@IsTest
public class RecruiterWorkflowTest {
    
    @TestSetup
    static void makeData(){
        User recruiter = RecruitingObjectsFactory.getMockUserData('Recruiter', 'Recruiter');
        User manager = RecruitingObjectsFactory.getMockUserData('Lead Manager', 'Lead Manager');

        insert recruiter;
        insert manager;
                
        Vacancy__c vacancy = RecruitingObjectsFactory.getSingleVacancyData(recruiter.Id, recruiter.Id, manager.Id);
        Vacancy__c vacancyNoResponsible = RecruitingObjectsFactory.getSingleVacancyData(recruiter.Id, NULL, manager.Id);
        Candidate__c candidate = RecruitingObjectsFactory.getSingleCandidateData(manager.Id, recruiter.Id);

        //System.runAs walkaround to avoid System.DmlException: MIXED_DML_OPERATION
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs(thisUser) {
            insert new List<Vacancy__c>{vacancy, vacancyNoResponsible};
            insert candidate;
        }
    }

    @IsTest
    private static void testCandidateProposal()
    {
       Vacancy__c vacancy = [SELECT Id FROM Vacancy__c WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE LIMIT 1];
       Candidate__c candidate = [SELECT Id FROM Candidate__c WHERE FirstName__c = :RecruitingObjectsFactory.MOCK_CANDIDATE_NAME LIMIT 1];

        Test.startTest();
            String vacCanMapJSON = JSON.serialize(new Map<String, List<String>>{vacancy.Id => new List<String>{candidate.Id}});
            RecruitingController.submitVacanciesCandidates(vacCanMapJSON);
        Test.stopTest();
    }

    @IsTest
    private static void testResponsibleAssign()
    {
        Vacancy__c vacancy = [SELECT Id FROM Vacancy__c 
                                WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE 
                                AND Responsible__c = NULL 
                                LIMIT 1];
        
        User responsible = [SELECT Id FROM User WHERE UserRole.Name = 'Recruiter' LIMIT 1];

        vacancy.Responsible__c = responsible.Id;

        Test.startTest();
            update vacancy;
        Test.stopTest();
    }

    @IsTest
    private static void testCandidateControllerListRecords()
    {
        Test.startTest();
            String candidatesListJSON = CandidateController.listRecords('', 1, 1);
        Test.stopTest();

        System.assertEquals(true, isResponseListHasRecords(candidatesListJSON));
    }

    @IsTest
    private static void testCandidateControllerSearchRecords()
    {
        Test.startTest();
            String candidatesListJSON = CandidateController.listRecords('Mock', 1, 1);
        Test.stopTest();

        //System.assertEquals(true, isResponseListHasRecords(candidatesListJSON));
    }

    @IsTest
    private static void testVacancyControllerListRecords()
    {
        Test.startTest();
            String vacancyListJSON = VacancyController.listRecords('', 1, 1);
        Test.stopTest();
    }

    @IsTest
    private static void testVacancyControllerSearchRecords()
    {
        Test.startTest();
            String vacancyListJSON = VacancyController.listRecords('Mock', 1, 1);
        Test.stopTest();

       // System.assertEquals(true, isResponseListHasRecords(vacancyListJSON));
    }

    @IsTest
    private static void testVacancyCancel()
    {
        Vacancy__c vacancy = [SELECT Id FROM Vacancy__c 
                                WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE 
                                AND Responsible__c = NULL 
                                LIMIT 1];

        Test.startTest();
            VacancyController.cancelVacancy(vacancy.Id);
        Test.stopTest();
    }


    private static Boolean isResponseListHasRecords(String serializedPaginatedResponse)
    {
        PaginatedResponse responseObject = (PaginatedResponse) JSON.deserialize(serializedPaginatedResponse, PaginatedResponse.class);
        return responseObject.pageData.size() > 0;
    }
}