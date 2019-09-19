/* eslint-disable dot-notation */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
import {track, wire, api} from 'lwc';
import listRecords from '@salesforce/apex/CandidateController.listRecords';
import AbstractList from 'c/abstractList';

export default class vacancyList extends AbstractList {

    @track searchTerm = '';
    @track candidateList = [];

    $selectedRecordsId;

    @api
    set selectedRecordsId(value)
    {
        this.$selectedRecordsId = value;
        this.checkSelected();
    }

    get selectedRecordsId(){
        return this.$selectedRecordsId || [];
    }

    get isHasResults() {
        return this.candidateList.length > 0;
    }

    @wire(listRecords, {searchTerm: '$searchTerm', pageCurrent: 1, requestIndex: '$requestIndex'})
    load({data, error}) {
        data && (this.candidateList = JSON.parse(data).pageData);
        error && console.warn(error);
        this.checkSelected();
    }

    handleCandidateChose(event) {
        const chosenId = event.detail;
        if (!chosenId) return;

        const chosenIndex = this.$selectedRecordsId.indexOf(event.detail);

        if (chosenIndex !== -1) {
            this.$selectedRecordsId.splice(chosenIndex, 1);
        } else {
            this.$selectedRecordsId.push(chosenId);
        }

        this.checkSelected();
        this.sendCandidateChosenEvent();
    }

    sendCandidateChosenEvent()
    {
        let candidateChosenEvent = new CustomEvent('candidatechosen', {
           detail: JSON.stringify(this.$selectedRecordsId)
        });

        this.dispatchEvent(candidateChosenEvent);
    }

    checkSelected()
    {
        this.candidateList.map(entry => {
            entry['isSelected'] = (this.$selectedRecordsId.indexOf(entry.Id) !== -1);
            return entry;
        });
    }
}