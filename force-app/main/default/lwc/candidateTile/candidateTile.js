import {LightningElement, api, track} from 'lwc';

export default class CandidateTile extends LightningElement {
    @api candidate;

    @api
    get tileClass()
    {
        return this.candidate && this.candidate.isSelected ?
            'slds-card card-selected' :
            'slds-card';
    }
    @api
    get recordLink()
    {
        return `/lightning/r/kk_recruiting__Candidate__c/${this.candidate.Id}/view`;
    }

    @api
    get candidateFullName()
    {
        return this.candidate.kk_recruiting__LastName__c + ' ' + this.candidate.kk_recruiting__FirstName__c;
    }

    handleClick()
    {
        const candidateChosenEvent = new CustomEvent('candidatechosen',{
            detail: this.candidate.Id
        });

        this.dispatchEvent(candidateChosenEvent);
    }
}