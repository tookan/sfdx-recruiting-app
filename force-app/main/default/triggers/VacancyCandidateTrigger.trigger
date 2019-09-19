trigger VacancyCandidateTrigger on VacancyCandidate__c (before update, before insert, after update) {

    /*===================
    Before INSERT section
    - generates unique id's for junction records
     ====================*/
    if (Trigger.isBefore && Trigger.isInsert) {
        for (VacancyCandidate__c vacCan : Trigger.new) {
            vacCan.UniqueID__c = String.valueOf(vacCan.Vacancy__c) + String.valueOf(vacCan.Candidate__c);
        }
    }

    /*====================
    Before UPDATE section
    - updates related vacancies related to approved
      vacancy-candidate junctions
    ======================*/
    if (Trigger.isBefore && Trigger.isUpdate) {

        //purposed to dedicate only approved vacancy candidates
        List<VacancyCandidate__c> approvedVacCan = new List<VacancyCandidate__c>();

        for (VacancyCandidate__c vacCan : Trigger.new) {
            if (vacCan.Approved__c) {
                approvedVacCan.add(vacCan);
            }
        }

        if (approvedVacCan.size() > 0) {
            approvedVacCan = VacancyCandidateHelper.filterValidateDuplicates(approvedVacCan);
        }

        VacancyCandidateHelper.closeVacancies(approvedVacCan);
    }

    /*====================
    Before UPDATE section
    - return vacancies to recruiters
      if no vacancy-candidate records waiting 
      for approval remain 
    ======================*/

    if(Trigger.isAfter && Trigger.isUpdate)
    {
        List<String> usedVacanciesId = new List<String>();
        Integer i = 0;

        for (VacancyCandidate__c vacCan : Trigger.new) {

            if(!usedVacanciesId.contains(vacCan.Vacancy__c) && (vacCan.Processed__c && !Trigger.old.get(i).Processed__c))
            {
                usedVacanciesId.add(vacCan.Vacancy__c);
            }

            i+=1;
        }

        VacancyCandidateHelper.checkExecuteVacanciesReopen(usedVacanciesId);
    }
}