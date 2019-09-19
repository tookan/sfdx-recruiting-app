/* eslint-disable dot-notation */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
import {LightningElement, track, wire, api} from 'lwc';
import listRecords from '@salesforce/apex/VacancyController.listRecords';

export default class vacancyList extends LightningElement {

    @track searchTerm = '';
    @track vacancyList = [];
    @track selectedRecordId;
    requestIndex = 0;

    @api
    get reloadListTrigger() {
        return false;
    }

    set reloadListTrigger(value) {
        this.forceListRecords();
    }

    @wire(listRecords, {searchTerm: '$searchTerm', pageCurrent: 1, requestIndex: '$requestIndex'})
    load(response) {
        this.rawRecordsData = response;
        response.data && (this.vacancyList = JSON.parse(response.data).pageData);
        response.error && console.warn(response.error);
        this.checkSelected();
    }

    forceListRecords()
    {
        this.requestIndex++;
    }

    get isHasResults() {
        return this.vacancyList.length > 0;
    }

    handleSearch(event) {

        window.clearTimeout(this.delaySearchInputProcessing);

        const delayedSearchTerm = event.target.value;

        this.delaySearchInputProcessing = setTimeout(() => {
            this.searchTerm = delayedSearchTerm;
            if(this.searchTerm.length === 0) this.forceListRecords();
        }, 300);
    }

    handleVacancyChose(event) {
        this.selectedRecordId === event.detail ?
            this.selectedRecordId = '' :
            this.selectedRecordId = event.detail;

        this.checkSelected();
        this.sendVacancyChosenEvent();
    }

    sendVacancyChosenEvent() {
        const vacancyChosenEvent = new CustomEvent('vacancychosen', {
            detail: this.selectedRecordId
        });

        this.dispatchEvent(vacancyChosenEvent);
    }

    checkSelected() {
        let previousSelectedRecordId = this.selectedRecordId;
        let selectedRecordsCount = 0;
        this.vacancyList.map(entry => {
            entry['isSelected'] = entry.Id === this.selectedRecordId;
            entry['isSelected'] && selectedRecordsCount++;
            return entry;
        });
        if(selectedRecordsCount === 0) {
            this.selectedRecordId = '';
            if(previousSelectedRecordId !== this.selectedRecordId ) this.handleVacancyChose({detail: ''});
        }
    }
}