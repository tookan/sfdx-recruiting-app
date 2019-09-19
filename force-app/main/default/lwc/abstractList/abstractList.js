/* eslint-disable dot-notation */
/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-expressions */
import { LightningElement, api } from 'lwc';

export default class AbstractList extends LightningElement {

    connectedCallback()
    {
        this.forceListRecords();
    }

    forceListRecords()
    {
        this.requestIndex = parseInt((''+Date.now()).substr(-1, 5), 10);
    }

    handleSearch(event) {

        window.clearTimeout(this.delaySearchInputProcessing);

        const delayedSearchTerm = event.target.value;

        this.delaySearchInputProcessing = setTimeout(() => {
            this.searchTerm = delayedSearchTerm;
        }, 300);
        
        this.checkRenderOptions();
    }

    checkRenderOptions(){}

}