public with sharing class VacancyHelper {
  private Vacancy__c vacancy { get; set; }
  //
  public static final String VACANCY_CLOSED_STATUS = 'Closed';
  public static final String VACANCY_CANCELLED_STATUS = 'Cancelled';
  public final static String[] CLOSED_STATUSES = new List<String>{
    VACANCY_CLOSED_STATUS,
    'Cancelled'
  };
  public final static String IN_PROCESS_STATUS = 'In-Process';

  public void setNewVacancy(Vacancy__c vacancy) {
    this.vacancy = vacancy;
  }

  public VacancyHelper() {
  }

  public VacancyHelper(Vacancy__c vacancy) {
    this.vacancy = vacancy;
  }

  private static Vacancy__c getQualifiedRecord(String vacancyId) {
    return [
      SELECT
        OwnerId,
        Status__c,
        Responsible__c,
        Candidate__c,
        VacancyOwner__c,
        Candidate__r.Status__c
      FROM Vacancy__c
      WHERE Id = :vacancyId
      LIMIT 1
    ];
  }

  public VacancyHelper setResponsibleAsOwner() {
    vacancy.OwnerId = vacancy.Responsible__c;
    return this;
  }

  public VacancyHelper setInProcess() {
    vacancy.Status__c = 'In-Process';
    return this;
  }

  public VacancyHelper setManagerAsOwner() {
    if (vacancy.OwnerId != vacancy.VacancyOwner__c) {
      vacancy.OwnerId = vacancy.VacancyOwner__c;
    }

    return this;
  }

  public VacancyHelper hireCandidate() {
    Candidate__c candidate = [
      SELECT Status__c
      FROM Candidate__c
      WHERE Id = :vacancy.Candidate__c
    ];

    candidate.Status__c = 'Hired';

    update candidate;
    vacancy.Candidate__r = candidate;

    return this;
  }
}
