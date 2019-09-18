/**
 * Created by kkukh on 9/10/2019.
 */

import {LightningElement, api, track} from 'lwc';
import submitVacanciesCandidates from "@salesforce/apex/RecruitingController.submitVacanciesCandidates";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class RecruiterPage extends LightningElement {

    /**
     * {
     *     vacancyId1: [candidateIds'],
     *     vacancyId2: [candidateIds'],
     * }
     * */
    vacancyCandidateMap = {};
    @api  chosenVacancyId = '';

    @track
    isCandidateListRendered = false;

    @track
    isSubmitShown = false;

    @api
    get selectedCandidates() {
        return this.vacancyCandidateMap[this.chosenVacancyId] || [];
    }

    onVacancyChosen(event) {

        this.chosenVacancyId = event.detail;
        this.vacancyCandidateMap[this.chosenVacancyId] = !!this.vacancyCandidateMap[this.chosenVacancyId] ?
            this.vacancyCandidateMap[this.chosenVacancyId] :
            [];
        this.checkRenderOptions();
    }

    onCandidateChosen(event) {

        this.vacancyCandidateMap[this.chosenVacancyId] = JSON.parse(event.detail);
        this.checkRenderOptions();
    }

    checkRenderOptions() {
        this.isSubmitShown = this.selectedCandidates.length > 0 && this.chosenVacancyId;
        this.isCandidateListRendered = !!this.chosenVacancyId;
    }

    submitVacancy() {
        let vacCanMap = {};
        vacCanMap[this.chosenVacancyId] = this.selectedCandidates;
        let vacCanMapJson = JSON.stringify(vacCanMap);
        submitVacanciesCandidates({vacCanMapJson: vacCanMapJson}).catch(err => {
            this.showErrorToast(err.body.message);
        }).finally(() => {
            this.clearSelection();
        });
    }

    showErrorToast(errorMessage) {
        const event = new ShowToastEvent({
            variant: 'error',
            title: 'Error has occurred',
            message: errorMessage
        });
        this.dispatchEvent(event);
    }

    clearSelection()
    {
        this.vacancyCandidateMap[this.chosenVacancyId] = [];
        this.chosenVacancyId = '';
        this.reloadVacanciesTrigger = !this.reloadVacanciesTrigger;
        this.selectedCandidates = [];
        this.checkRenderOptions();
    }

}