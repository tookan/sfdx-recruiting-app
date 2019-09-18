public with sharing class VacancyCandidateHelper {

    static final String VAC_CAN_DUPLICATE = 'Vacancy/Candidate already approved with another Candidate/Vacancy';
    static final String ACTION_APPROVE = 'Approve';
    static final String ACTION_REJECT = 'Reject';
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


    public static Approval.ProcessResult processApprovalWorkItem(String action, ProcessInstanceWorkitem workItem) {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction(action);
        req.setWorkitemId(workItem.Id);

        return Approval.process(req);
    }


    public static void acceptVacancyCandidateApprovals(VacancyCandidate__c[] vacCanIdList) {

        List<ProcessInstanceWorkitem> instanceWorkitems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :vacCanIdList
        ];

        for (ProcessInstanceWorkitem instanceWorkitem : instanceWorkitems) {
            processApprovalWorkItem(ACTION_APPROVE, instanceWorkitem);
        }
    }

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

        rejectVacancyCandidateApprovals(vacCanTargetList);
    }

    public static void rejectVacancyCandidateApprovals(List<VacancyCandidate__c> vacCanTargetList) {
        List<ProcessInstanceWorkitem> instanceWorkitems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :vacCanTargetList
        ];

        for (ProcessInstanceWorkitem instanceWorkitem : instanceWorkitems) {
            processApprovalWorkItem(ACTION_REJECT, instanceWorkitem);
        }
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