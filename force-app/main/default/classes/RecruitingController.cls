/**
 * Created by kkukh on 9/10/2019.
 */

public with sharing class RecruitingController {
  @AuraEnabled
  public static void submitVacanciesCandidates(String vacCanMapJson) {
    Map<String, List<String>> vacCanMap = (Map<String, List<String>>) JSON.deserialize(
      vacCanMapJson,
      Map<String, List<String>>.class
    );

    Set<String> vacanciesId = vacCanMap.keySet();
    List<VacancyCandidate__c> vacCanList = new List<VacancyCandidate__c>();

    for (String vacancyId : vacanciesId) {
      vacCanList.addAll(
        createJunctionRecords(vacancyId, vacCanMap.get(vacancyId))
      );
    }

    upsert vacCanList UniqueID__c;

    submitForApproval(vacCanList);
    transferVacanciesToManager(vacanciesId);
  }

  public static List<VacancyCandidate__c> createJunctionRecords(
    String vacancyId,
    List<String> candidatesId
  ) {
    List<VacancyCandidate__c> vacCanList = new List<VacancyCandidate__c>();

    for (String candidateId : candidatesId) {
      vacCanList.add(
        new VacancyCandidate__c(
          Vacancy__c = vacancyId,
          Candidate__c = candidateId,
          UniqueID__c = (vacancyId + candidateId)
        )
      );
    }

    return vacCanList;
  }

  public static void submitForApproval(VacancyCandidate__c[] vacCanList) {
    Map<Id, VacancyCandidate__c> vacCanOwnerMap = new Map<Id, VacancyCandidate__c>(
      [
        SELECT Id, Vacancy__r.VacancyOwner__c
        FROM VacancyCandidate__c
        WHERE Id IN :vacCanList
      ]
    );

    for (VacancyCandidate__c vacCan : vacCanList) {
      Approval.ProcessSubmitRequest vacCanApproveReq = new Approval.ProcessSubmitRequest();

      vacCanApproveReq.setObjectId(vacCan.Id);
      vacCanApproveReq.setSubmitterId(UserInfo.getUserId());
      vacCanApproveReq.setSkipEntryCriteria(true);
      vacCanApproveReq.setNextApproverIds(
        new List<Id>{ vacCanOwnerMap.get(vacCan.Id).Vacancy__r.VacancyOwner__c }
      );
      vacCanApproveReq.setProcessDefinitionNameOrId(
        'Approve_Multiple_Candidates'
      );

      Approval.ProcessResult vacCanApproveRes = Approval.process(
        vacCanApproveReq
      );
    }
  }

  public static void transferVacanciesToManager(Set<String> vacanciesId) {
    List<Vacancy__c> vacanciesList = [
      SELECT Id, OwnerId, VacancyOwner__c
      FROM Vacancy__c
      WHERE Id IN :vacanciesId
    ];

    for (Vacancy__c vacancy : vacanciesList) {
      vacancy.SubmitedByRecruiter__c = true;
      vacancy.OwnerId = vacancy.VacancyOwner__c;
    }

    update vacanciesList;
  }
}
