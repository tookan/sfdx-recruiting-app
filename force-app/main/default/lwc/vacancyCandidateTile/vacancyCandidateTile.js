/**
 * Created by kkukh on 9/11/2019.
 */

import {LightningElement, api} from 'lwc';
import acceptApprovals from "@salesforce/apex/VacancyCandidateController.acceptApprovals";
import rejectApprovals from "@salesforce/apex/VacancyCandidateController.rejectApprovals";

export default class VacancyCandidateTile extends LightningElement {

    @api vacCan;

    @api
    get tileClass()
    {
        return this.vacCan && this.vacCan.isVacCanSelected ?
            'slds-card card-selected' :
            'slds-card';
    }

    get fullCandidateName() {
        return this.vacCan.kk_recruiting__Candidate_Pivot__r.kk_recruiting__FirstName__c
            + ' ' +
            this.vacCan.kk_recruiting__Candidate_Pivot__r.kk_recruiting__LastName__c;
    }

    get vacancyTitle()
    {
        return this.vacCan.kk_recruiting__Title__c;
    }

    get tileLabel()
    {
        return `${this.fullCandidateName} promoted as ${this.vacancyTitle}`;
    }

    get recordLink()
    {
        return `/lightning/r/kk_recruiting__VacancyCandidate__c/${this.vacCan.pivotId}/view`;
    }

    handleClick()
    {
        const recordChosen = new CustomEvent('vaccanchosen',{
            detail: this.vacCan.pivotId
        });

        this.dispatchEvent(recordChosen);
    }

    sendApprovalEvent(event)
    {
        const action = event.target.getAttribute('id').includes('accept-request') ? 'accept' : 'reject';

        const approvalEvent = new CustomEvent('sendapprovalevent', {
            detail: JSON.stringify({vacCanId: this.vacCan.pivotId, action: action})
        });

        this.dispatchEvent(approvalEvent);
    }

}