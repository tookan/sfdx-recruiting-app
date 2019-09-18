/* eslint-disable dot-notation */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
import {LightningElement, track, wire, api} from 'lwc';
import listRecords from '@salesforce/apex/VacancyController.listRecords';
import {refreshApex} from '@salesforce/apex';

export default class vacancyList extends LightningElement {

    @track searchTerm = '';
    @track vacancyList = [];
    @track selectedRecordId;

    @api
    get reloadListTrigger() {
        return false;
    }

    set reloadListTrigger(value) {
        this.reloadRecords();
    }

    @wire(listRecords, {searchTerm: '$searchTerm', pageCurrent: 1})
    load(response) {
        this.rawRecordsData = response;
        response.data && (this.vacancyList = JSON.parse(response.data).pageData);
        response.error && console.warn(response.error);
        this.checkSelected();
    }

    reloadRecords()
    {
        if(this.rawRecordsData.data){
            refreshApex(this.rawRecordsData);
        }
    }

    get isHasResults() {
        return this.vacancyList.length > 0;
    }

    handleSearch(event) {

        window.clearTimeout(this.delaySearchInputProcessing);

        const delayedSearchTerm = event.target.value;

        this.delaySearchInputProcessing = setTimeout(() => {
            this.searchTerm = delayedSearchTerm;
            if(this.searchTerm.length === 0) this.reloadRecords();
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
        this.vacancyList.map(entry => {
            entry['isSelected'] = entry.Id === this.selectedRecordId;
            return entry;
        });
    }
}