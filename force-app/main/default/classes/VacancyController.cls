public with sharing class VacancyController {

    @AuraEnabled(Cacheable=true)
    public static String listRecords(String searchTerm, Integer pageCurrent)
    {
        RequestHelper requestHelper = new VacancyRequestHelper();
        return CustomObjectController.executeListRecords(searchTerm, pageCurrent, requestHelper);
    }

     @AuraEnabled
    public static String cancelVacancy(String recordId){
        
        Vacancy__c vac = [SELECT Status__c, RecordTypeId FROM Vacancy__c WHERE Id = :recordId];

        Id closedVacancyRecordTypeId = Schema.SObjectType.Vacancy__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();

        vac.Status__c = VacancyHelper.VACANCY_CANCELLED_STATUS;
        vac.RecordTypeId = closedVacancyRecordTypeId;
        
        update vac;

        return '{"success":"true"}';
    }

    class VacancyRequestHelper extends RequestHelper {

        public override List<SObject> listRecordsRequest() {
            return [
                    SELECT Id, Name, Title__c, Level__c, Comments__c, StartDate__c, Status__c, OwnerId
                    FROM Vacancy__c
                    WHERE SubmitedByRecruiter__c = FALSE
                    AND Status__c = :VacancyHelper.IN_PROCESS_STATUS
                    LIMIT :takeRecordsCount
                    OFFSET :skipRecordsCount
            ];
        }

        public override List<SObject> listRecordsSearch() {
            List<List<SObject>> soslResult = (List<List<SObject>>) [
                    FIND :searchTerm
                   IN ALL FIELDS RETURNING kk_recruiting__Vacancy__c(Id, Name,  kk_recruiting__Title__c,  
                   kk_recruiting__Level__c,  
                   kk_recruiting__Comments__c,  kk_recruiting__StartDate__c,  
                   kk_recruiting__Status__c, OwnerId, kk_recruiting__SubmitedByRecruiter__c  
                   WHERE ( kk_recruiting__Status__c NOT IN  :VacancyHelper.CLOSED_STATUSES))
            ];

            List<Vacancy__c> recordsResult = soslResult.get(0);
            List<Vacancy__c> result = this.paginateSearchList(recordsResult);

            return result;
        }
    }
}