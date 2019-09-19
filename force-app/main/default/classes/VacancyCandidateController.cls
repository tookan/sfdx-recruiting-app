public with sharing class VacancyCandidateController {


    @AuraEnabled(Cacheable=true)
    public static String listRecords(String searchTerm, Integer pageCurrent, Integer requestIndex) {
        RequestHelper requestHelper = new VacancyCandidateRequestHelper();
        return CustomObjectController.executeListRecords(searchTerm, pageCurrent, requestHelper);
    }

    @AuraEnabled
    public static String acceptApprovals(String vacCanJSON) {

        List<VacancyCandidate__c> vacCanList = getObjectListFromIdJSON(vacCanJSON);

        List<VacancyCandidate__c> cleanVacCanList = VacancyCandidateHelper.filterValidateDuplicates(vacCanList);

        if(VacancyCandidateHelper.errorMap.isEmpty()){
            
            VacancyCandidateHelper.processVacancyCandidateApprovals(VacancyCandidateHelper.ACTION_APPROVE, vacCanList);
            VacancyCandidateHelper.markVacancyCandiadatesAsProcessed(vacCanList);
            VacancyCandidateHelper.cleanupVacancyCandidateApprovals(cleanVacCanList);
        }

        Boolean responseStatus = VacancyCandidateHelper.errorMap.isEmpty();

        return  '{"success":"' + responseStatus + '","errors":' + JSON.serialize(VacancyCandidateHelper.errorMap) + '}';
    }

    @AuraEnabled
    public static String rejectApprovals(String vacCanJSON)
    {
       List<VacancyCandidate__c> vacCanList = getObjectListFromIdJSON(vacCanJSON);
        VacancyCandidateHelper.processVacancyCandidateApprovals(VacancyCandidateHelper.ACTION_REJECT, vacCanList);
        VacancyCandidateHelper.markVacancyCandiadatesAsProcessed(vacCanList);
        return '{"success":true,"errors":[]}';
    }

    public static List<VacancyCandidate__c> getObjectListFromIdJSON(String vacCanJSON)
    {
        List<String> vacCanIdList = (List<String>) JSON.deserialize(vacCanJSON, List<String>.class);
        return [
                SELECT Id, Vacancy__c, Candidate__c, Processed__c
                FROM VacancyCandidate__c
                WHERE Id IN :vacCanIdList
        ];
    }

    class VacancyCandidateRequestHelper extends RequestHelper {

        public override List<SObject> listRecordsRequest() {
            return [
                    SELECT Id, Name, Title__c, Level__c, Comments__c, StartDate__c, Status__c, OwnerId, Description__c, (
                            SELECT Id, Candidate__r.Id, Candidate__r.Name, Candidate__r.FirstName__c,
                                    Candidate__r.LastName__c, Candidate__r.Comments__c, Candidate__r.Email__c,
                                    Candidate__r.Status__c, Candidate__r.OwnerId, Candidate__r.Location__c
                            FROM Candidate_Pivot__r
                            WHERE Processed__c = FALSE
                    )
                    FROM Vacancy__c
                    WHERE Id IN (SELECT Vacancy__c FROM VacancyCandidate__c WHERE Processed__c = FALSE)
                    AND Status__c = :VacancyHelper.IN_PROCESS_STATUS
                    LIMIT :takeRecordsCount
                    OFFSET :skipRecordsCount
            ];
        }

        public override List<SObject> listRecordsSearch() {

            String wildcardSearchTerm = '%' + searchTerm + '%';

            return [
                    SELECT Id, Name, Title__c, Level__c, Comments__c, StartDate__c, Status__c, OwnerId, Description__c, (
                            SELECT Id, Candidate__r.Id, Candidate__r.Name, Candidate__r.FirstName__c,
                                    Candidate__r.LastName__c, Candidate__r.Comments__c, Candidate__r.Email__c,
                                    Candidate__r.Status__c, Candidate__r.OwnerId, Candidate__r.Location__c
                            FROM Candidate_Pivot__r
                            WHERE Processed__c = FALSE
                    )
                    FROM Vacancy__c
                    WHERE Id IN (SELECT Vacancy__c FROM VacancyCandidate__c WHERE Processed__c = FALSE)
                    AND Status__c = :VacancyHelper.IN_PROCESS_STATUS
                    AND (Candidate__r.FirstName__c LIKE :wildcardSearchTerm OR
                    Candidate__r.LastName__c LIKE :wildcardSearchTerm OR
                    Title__c LIKE :wildcardSearchTerm)
                    LIMIT :takeRecordsCount
                    OFFSET :skipRecordsCount
            ];
        }
    }
}