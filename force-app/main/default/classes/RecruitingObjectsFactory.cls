public class RecruitingObjectsFactory {

    public static final String MOCK_VACANCY_TITLE = 'Mock Vacancy';
    public static final String MOCK_CANDIDATE_NAME = 'Mock Candidate';

    public static User getMockUserData(String roleName, String profileName){

        Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        Id roleId = [SELECT Id FROM UserRole WHERE Name = :roleName].Id;

        return new User(
                ProfileId = profileId,
                UserRoleId = roleId,
                LastName = roleName,
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
    }
    
    public static Vacancy__c getSingleVacancyData(String ownerId, String responsibleId, String vacncyOwnerId)
    {
        Vacancy__c newVac = new Vacancy__c();
            newVac.PromoDescription__c = 'SAMPLE';
            newVac.Responsible__c = responsibleId;
            newVac.Title__c = MOCK_VACANCY_TITLE;
            newVac.StartDate__c = Date.newInstance(2019, 9, 22);
            newVac.Level__c = 'd0';
            newVac.Status__c = 'New';
            newVac.VacancyOwner__c = vacncyOwnerId;
            newVac.OwnerId = ownerId;

        return newVac;
    }

    public static Candidate__c getSingleCandidateData(String ownerId, String recruiterId)
    {
        return new Candidate__c(
            Email__c = 'test@emails.com' + System.currentTimeMillis(),
            FirstName__c = MOCK_CANDIDATE_NAME,
            LastName__c = 'Mock Surname',
            OwnerId =  ownerId,
            Recruiter__c = recruiterId,
            Salary__c = 10000.00,
            Status__c  = 'Validated by HR'
        );
    }

    public static VacancyCandidate__c getSingleVacancyCandidateJunction(Vacancy__c vacancy, Candidate__c candidate)
    {
        return new VacancyCandidate__c (
            Vacancy__c = vacancy.Id,
            Candidate__c = candidate.Id
        );
    }
}