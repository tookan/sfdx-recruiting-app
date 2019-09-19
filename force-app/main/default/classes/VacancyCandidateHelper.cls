public with sharing class VacancyCandidateHelper {

    public static final String VAC_CAN_DUPLICATE = 'Vacancy/Candidate already approved with another Candidate/Vacancy';
    public static final String ACTION_APPROVE = 'Approve';
    public static final String ACTION_REJECT = 'Reject';
    public static Map<String, List<String>> errorMap = new Map<String, List<String>>();

    public static List<VacancyCandidate__c> filterValidateDuplicates(List<VacancyCandidate__c> vacCanList) {

        Set<Id> uniqueIds = new Set<Id>();
        List<VacancyCandidate__c> uniqueVacCans = new List<VacancyCandidate__c>();

        for (VacancyCandidate__c vacCan : vacCanList) {
            if (!uniqueIds.contains(vacCan.Vacancy__c) && !uniqueIds.contains(vacCan.Candidate__c)) {
                uniqueIds.add(vacCan.Vacancy__c);
                uniqueIds.add(vacCan.Candidate__c);
                uniqueVacCans.add(vacCan);
            } else {
                addDuplicateError(vacCan);
            }
        }

        return uniqueVacCans;
    }

    public static void closeVacancies(List<VacancyCandidate__c> vacCanList) {

        Map<Id, Id> vacCanIdMap = new Map<Id, Id>();

        for (VacancyCandidate__c vacCan : vacCanList) {
            vacCanIdMap.put(vacCan.Vacancy__c, vacCan.Candidate__c);
        }

        Set<Id> vacanciesIdList = vacCanIdMap.keySet();

        Id closedVacancyRecordTypeId = Schema.SObjectType.Vacancy__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();

        List<Vacancy__c> vacanciesList = [SELECT Id, Status__c, Candidate__c FROM Vacancy__c WHERE Id IN :vacanciesIdList];

        for (Vacancy__c vacancy : vacanciesList) {
            vacancy.Candidate__c = vacCanIdMap.get(vacancy.Id);
            vacancy.Status__c = VacancyHelper.VACANCY_CLOSED_STATUS;
            vacancy.RecordTypeId = closedVacancyRecordTypeId;
        }

        update vacanciesList;
    }

    public static void markVacancyCandiadatesAsProcessed(List<VacancyCandidate__c> vacCanList)
    {
        for(VacancyCandidate__c vacCan : vacCanList)
        {
            vacCan.Processed__c = true;
        }
        update vacCanList;
    }


    public static  List<Approval.ProcessResult> processVacancyCandidateApprovals(String action, List<VacancyCandidate__c> vacCanTargetList) {

        List<ProcessInstanceWorkitem> instanceWorkitems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :vacCanTargetList
        ];

        List<Approval.ProcessResult> approvalResults = new List<Approval.ProcessResult>();

        for (ProcessInstanceWorkitem instanceWorkitem : instanceWorkitems) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction(action);
            req.setWorkitemId(instanceWorkitem.Id);
            approvalResults.add(Approval.process(req));
        }

        return approvalResults;
    }

    /**
     * reject pending approval requests 
     * that related to already processed
     */
    public static void cleanupVacancyCandidateApprovals(VacancyCandidate__c[] vacCanList) {

        List<String> vacanciesIdList = new List<String>();
        List<String> candidatesIdList = new List<String>();

        for (VacancyCandidate__c vacCan : vacCanList) {
            vacanciesIdList.add(vacCan.Vacancy__c);
            candidatesIdList.add(vacCan.Candidate__c);
        }

        List<VacancyCandidate__c> vacCanTargetList = [
                SELECT Id
                FROM VacancyCandidate__c
                WHERE Id NOT IN :vacCanList
                AND (Vacancy__c IN :vacanciesIdList OR Candidate__c IN :candidatesIdList)
        ];
    
        processVacancyCandidateApprovals(ACTION_REJECT, vacCanTargetList);
        markVacancyCandiadatesAsProcessed(vacCanTargetList);
    }

    public static void addDuplicateError(VacancyCandidate__c vacCan) {
        if (errorMap.containsKey(vacCan.Id)) {
            errorMap.get(vacCan.Id).add(VAC_CAN_DUPLICATE);
        } else {
            errorMap.put(vacCan.Id, new List<String>{
                    VAC_CAN_DUPLICATE
            });
        }
    }

    @Future
    public static void checkExecuteVacanciesReopen(String[] vacanciesId) {
        //find all junction records for specified records
        Map<Id, VacancyCandidate__c> vacCanMap = new Map<Id, VacancyCandidate__c>([
                SELECT Id, Vacancy__c, Vacancy__r.Status__c, Vacancy__r.Responsible__c
                FROM VacancyCandidate__c
                WHERE Id IN :vacanciesId
                AND Vacancy__r.Status__c = :VacancyHelper.IN_PROCESS_STATUS
        ]);

        //find pending approval processes for junction records
        //if vacancy has no pending candidates proposal it will be returned to recruiter
        //by unchecking SubmitedByRecruiter__c
        for (ProcessInstance vacCanProc : [
                SELECT Id, TargetObjectId, (SELECT Id, StepStatus, Comments FROM StepsAndWorkitems WHERE StepStatus = 'Pending')
                FROM ProcessInstance
                WHERE TargetObjectId IN :vacCanMap.keySet()
        ]) {

            Integer vacCanIndex = vacanciesId.indexOf(vacCanMap.get(vacCanProc.TargetObjectId).Vacancy__c);

            if (vacCanIndex != -1) {
                vacanciesId.remove(vacCanIndex);
            }
        }

        List<Vacancy__c> vacanciesToUpdate = [
                SELECT Id, SubmitedByRecruiter__c, Responsible__c
                FROM Vacancy__c
                WHERE Id IN :vacanciesId
        ];

        for (Vacancy__c vacancy : vacanciesToUpdate) {
            vacancy.SubmitedByRecruiter__c = false;
            vacancy.OwnerId = vacancy.Responsible__c;
        }

        update vacanciesToUpdate;
    }
}