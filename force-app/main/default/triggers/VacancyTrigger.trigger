trigger VacancyTrigger on Vacancy__c (before update) {

   Integer listIndex = 0;
   List<Vacancy__c> vacanciesToUpdate = new List<Vacancy__c>();
   VacancyHelper vacHelper = new VacancyHelper();

    for(Vacancy__c vacancy : Trigger.new)
    {
        vacHelper.setNewVacancy(vacancy);
        
        if(vacancy.Status__c == 'Closed' 
            && Trigger.old.get(listIndex).Status__c != 'Closed'
            && vacancy.Candidate__c != null)
        {
            vacHelper.hireCandidate().setManagerAsOwner();
            break;
        }

        if(vacancy.Responsible__c != null && Trigger.old.get(listIndex).Responsible__c == null)
        {
           //if new recruiter assigned for vacancy assign him as record owner
           vacHelper.setResponsibleAsOwner().setInProcess();
        }
        listIndex += 1;
    }

}