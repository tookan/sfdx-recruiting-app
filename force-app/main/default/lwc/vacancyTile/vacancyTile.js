/**
 * Created by kkukh on 9/6/2019.
 */

import {LightningElement, api} from 'lwc';

export default class VacancyTile extends LightningElement {
    @api vacancy;

    @api
    get tileClass()
    {
        return this.vacancy && this.vacancy.isSelected ?
            'slds-card card-selected' :
            'slds-card';
    }

    @api
    get recordLink()
    {
        return `/lightning/r/kk_recruiting__Vacancy__c/${this.vacancy.Id}/view`;
    }

    handleClick()
    {
        const vacancyChosenEvent = new CustomEvent('vacancychosen', {
            detail: this.vacancy.Id
        });
        this.dispatchEvent(vacancyChosenEvent);
    }
}