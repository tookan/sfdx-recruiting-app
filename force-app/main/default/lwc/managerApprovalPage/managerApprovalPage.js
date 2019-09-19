/* eslint-disable dot-notation */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
import {wire, track} from 'lwc';
import listRecords from "@salesforce/apex/VacancyCandidateController.listRecords";
import acceptApprovals from "@salesforce/apex/VacancyCandidateController.acceptApprovals";
import rejectApprovals from "@salesforce/apex/VacancyCandidateController.rejectApprovals";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import AbstractList from 'c/abstractList';

export default class ManagerApprovalPage extends AbstractList {

    @track vacCanList = [];
    @track selectedRecordsId = [];
    @track searchTerm = '';
    @track isSubmitButtonsRendered = false;
  
    @wire(listRecords, {searchTerm: '$searchTerm', pageCurrent: 1, requestIndex: '$requestIndex'})
    load(result) {
        this.rawRecordsData = result;
        if (result.data) {
            this.parseRecordsData(result.data);
        }
        // eslint-disable-next-line no-unused-expressions
        result.error && console.warn(result.error);
    }

    get isAnyRecordsChosen() {
        return this.selectedRecordsId.length > 0;
    }

    checkRenderOptions()
    {
        this.isSubmitButtonsRendered = this.isAnyRecordsChosen;
    }

    handleRecordChose(event) {
        const chosenId = event.detail;

        const chosenIndex = this.selectedRecordsId.indexOf(event.detail);

        if (chosenIndex !== -1) {
            this.selectedRecordsId.splice(chosenIndex, 1);
        } else {
            this.selectedRecordsId.push(chosenId);
        }

        this.checkSelected();
    }

    handleTileApprovalRequest(event) {
        const eventDetail = JSON.parse(event.detail);

        if (eventDetail.action === 'accept') this.sendApprovalStatusChangeRequest(acceptApprovals, [eventDetail.vacCanId]);
        else if (eventDetail.action === 'reject') this.sendApprovalStatusChangeRequest(rejectApprovals, [eventDetail.vacCanId]);
    }

    parseRecordsData(dataJSON) {
        const dataList = JSON.parse(dataJSON).pageData;
        let vacCanList = [];

        dataList.forEach(vacEntry => {
            vacEntry.kk_recruiting__Candidate_Pivot__r.records.forEach(canEntry => {
                let vacEntryCopy = Object.assign({}, vacEntry);
                vacEntryCopy['kk_recruiting__Candidate_Pivot__r'] = canEntry.kk_recruiting__Candidate__r;
                //Id of VacancyCandidate__c record
                vacEntryCopy['pivotId'] = canEntry.Id;
                vacCanList.push(vacEntryCopy);
            });
        });

        this.vacCanList = vacCanList;
    }

    checkSelected() {
        this.checkRenderOptions();
        this.vacCanList.map(entry => {
            entry['isVacCanSelected'] = this.selectedRecordsId.indexOf(entry.pivotId) !== -1;
            return entry;
        });
    }

    acceptApprovals() {
        this.sendApprovalStatusChangeRequest(acceptApprovals);
    }

    rejectApprovals() {
        this.sendApprovalStatusChangeRequest(rejectApprovals);
    }

    sendApprovalStatusChangeRequest(apexMethod, payload = this.selectedRecordsId) {
        apexMethod({vacCanJSON: JSON.stringify(payload)})
            .then(response => {
                response = JSON.parse(response);
                if (response["success"] !== "false" && response["errors"]) {
                    this.showSuccessToast();
                } 
                if(response.errors.length) {
                    // eslint-disable-next-line guard-for-in
                    for (const key in response.errors) { 
                        this.showErrorToast(key, response.errors[key][0]);
                    }
                }
            })
            .finally(() => {
                this.selectedRecordsId = [];
                this.forceListRecords();
                this.checkRenderOptions();
            });
    }

    showSuccessToast(message = '') {
        const event = new ShowToastEvent({
            variant: 'success',
            title: 'Saved!',
            message: message
        });

        this.dispatchEvent(event);
    }

    showErrorToast(vacCanId, errorMessage) {
        let toastHeader = 'Candidate ';
        let vacCan = this.vacCanList.find(entry => entry.pivotId === vacCanId);

        if(vacCan)
        {
            toastHeader = `${toastHeader}
                            ${vacCan["kk_recruiting__Candidate_Pivot__r"].kk_recruiting__FirstName__c} 
                            ${vacCan["kk_recruiting__Candidate_Pivot__r"].kk_recruiting__LastName__c} 
                            cannot be assigned to vacancy ${vacCan.kk_recruiting__Title__c}`;
        }

        const event = new ShowToastEvent({
            variant: 'warning',
            title: toastHeader,
            message: errorMessage
        });

        this.dispatchEvent(event);
    }
}