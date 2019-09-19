public with sharing class CandidateController {

    public static final String VALIDATED_BY_HR_STATUS = 'Validated by HR';

    @AuraEnabled(Cacheable=true)
    public static String listRecords(String searchTerm, Integer pageCurrent, Integer requestIndex)
    {
        RequestHelper requestHelper = new CandidateRequestHelper();
        return CustomObjectController.executeListRecords(searchTerm, pageCurrent, requestHelper);
    }

    class CandidateRequestHelper extends RequestHelper {

        public override List<SObject> listRecordsRequest() {
            return [
                    SELECT Id, Name, kk_recruiting__FirstName__c, kk_recruiting__LastName__c, kk_recruiting__Comments__c, kk_recruiting__Email__c, kk_recruiting__Status__c, OwnerId, kk_recruiting__Location__c
                    FROM kk_recruiting__Candidate__c
                    WHERE Status__c = :CandidateController.VALIDATED_BY_HR_STATUS
                    LIMIT :takeRecordsCount
                    OFFSET :skipRecordsCount
            ];
        }

        public override List<SObject> listRecordsSearch() {
            List<List<SObject>> soslResult = (List<List<SObject>>) [
                    FIND :searchTerm
                    IN ALL FIELDS
                            RETURNING
                            kk_recruiting__Candidate__c(Id, Name, kk_recruiting__FirstName__c, 
                                        kk_recruiting__LastName__c, kk_recruiting__Comments__c, 
                                        kk_recruiting__Email__c, kk_recruiting__Status__c, OwnerId, 
                                        kk_recruiting__Location__c
                                    WHERE Status__c = :CandidateController.VALIDATED_BY_HR_STATUS)
            ];

            List<Candidate__c> recordsResult = soslResult.get(0);
            List<Candidate__c> result = paginateSearchList(recordsResult);
            return result;
        }
    }
}