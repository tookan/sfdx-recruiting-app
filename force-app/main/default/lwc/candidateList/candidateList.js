/**
 * Created by kkukh on 9/6/2019.
 */

import {LightningElement, track, wire, api} from 'lwc';
import listRecords from '@salesforce/apex/CandidateController.listRecords';

export default class vacancyList extends LightningElement {

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

    @wire(listRecords, {searchTerm: '$searchTerm', pageCurrent: 1})
    load({data, error}) {
        // eslint-disable-next-line no-unused-expressions
        data && (this.candidateList = JSON.parse(data).pageData);
        // eslint-disable-next-line no-console
        error && console.warn(error);

        this.checkSelected();
    }

    handleCandidateSearch(event) {

        window.clearTimeout(this.delaySearchInputProcessing);

        const delayedSearchTerm = event.target.value;

        this.delaySearchInputProcessing = setTimeout(() => {
            this.searchTerm = delayedSearchTerm;
        }, 300);

        this.checkSelected();
    }

    handleCandidateChose(event) {
        const chosenId = event.detail;
        if (!chosenId) return;

        const chosenIndex = this.$selectedRecordsId.indexOf(event.detail);

        if (chosenIndex != -1) {
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
            entry['isSelected'] = (this.$selectedRecordsId.indexOf(entry.Id) != -1);
            return entry;
        });
    }
}