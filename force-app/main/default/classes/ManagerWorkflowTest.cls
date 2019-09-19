@IsTest
private class ManagerWorkflowTest {
    
    @TestSetup
    static void makeData(){
        User recruiter = RecruitingObjectsFactory.getMockUserData('Recruiter', 'Recruiter');
        User manager = RecruitingObjectsFactory.getMockUserData('Lead Manager', 'Lead Manager');

        insert recruiter;
        insert manager;
                
        Vacancy__c vacancy = RecruitingObjectsFactory.getSingleVacancyData(recruiter.Id, recruiter.Id, manager.Id);
        Candidate__c candidate1 = RecruitingObjectsFactory.getSingleCandidateData(manager.Id, recruiter.Id);
        Candidate__c candidate2 = RecruitingObjectsFactory.getSingleCandidateData(manager.Id, recruiter.Id);
        //System.runAs walkaround to avoid System.DmlException: MIXED_DML_OPERATION
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs(thisUser) {

            insert vacancy;
            insert new List<Candidate__c>{candidate1, candidate2};

            String vacCanMapJSON = JSON.serialize(new Map<String, List<String>>{vacancy.Id => new List<String>{candidate1.Id, candidate2.Id}});
            RecruitingController.submitVacanciesCandidates(vacCanMapJSON);
        }
    }

    @IsTest
    static void testApprovalAccept()
    {
        VacancyCandidate__c vacCan = [SELECT Id, Vacancy__c, Candidate__c 
                                        FROM VacancyCandidate__c 
                                        WHERE Vacancy__c IN 
                                            (SELECT Id FROM Vacancy__c 
                                            WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE) 
                                        LIMIT 1];

        String vacCanIdListJSON = '["'+ vacCan.Id + '"]';

        Test.startTest();
            VacancyCandidateController.acceptApprovals(vacCanIdListJSON);
        Test.stopTest();
    }

    @IsTest
    static void testProcessedMark()
    {
        VacancyCandidate__c vacCan = [SELECT Id, Vacancy__c, Candidate__c 
                                        FROM VacancyCandidate__c 
                                        WHERE Vacancy__c IN 
                                            (SELECT Id FROM Vacancy__c 
                                            WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE) 
                                        LIMIT 1];

        vacCan.Processed__c = true;
        
        Test.startTest();
            update vacCan;
        Test.stopTest();
    }

    @IsTest
    static void testApprovalAcceptWithDuplicates()
    {
        List<VacancyCandidate__c> vacCanList = [SELECT Id, Vacancy__c, Candidate__c 
                                        FROM VacancyCandidate__c 
                                        WHERE Vacancy__c IN 
                                            (SELECT Id FROM Vacancy__c 
                                            WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE) 
                                    ];

        String vacCanIdListJSON = JSON.serialize(new String[]{vacCanList.get(0).Id, vacCanList.get(1).Id});

        Test.startTest();
            VacancyCandidateController.acceptApprovals(vacCanIdListJSON);
        Test.stopTest();

        System.assertEquals(true, !VacancyCandidateHelper.errorMap.isEmpty());
    }

    @IsTest
    static void testApprovalReject()
    {
        VacancyCandidate__c vacCan = [SELECT Id, Vacancy__c, Candidate__c 
                                        FROM VacancyCandidate__c 
                                        WHERE Vacancy__c IN 
                                            (SELECT Id FROM Vacancy__c 
                                            WHERE Title__c = :RecruitingObjectsFactory.MOCK_VACANCY_TITLE) 
                                        LIMIT 1];

        String vacCanIdListJSON = '["'+ vacCan.Id + '"]';

        Test.startTest();
            VacancyCandidateController.rejectApprovals(vacCanIdListJSON);
        Test.stopTest();
    }

    @IsTest
    private static void testVacancyCandidateListRecords()
    {
        Test.startTest();
            String candidatesListJSON = VacancyCandidateController.listRecords('', 1, 1);
        Test.stopTest();
    }

    @IsTest
    private static void testVacancyCandidateSearchRecords()
    {
        Test.startTest();
            String candidatesListJSON = VacancyCandidateController.listRecords('Mock', 1, 1);
        Test.stopTest();

        //System.assertEquals(true, isResponseListHasRecords(candidatesListJSON));
    }

    private static Boolean isResponseListHasRecords(String serializedPaginatedResponse)
    {
        PaginatedResponse responseObject = (PaginatedResponse) JSON.deserialize(serializedPaginatedResponse, PaginatedResponse.class);
        return responseObject.pageData.size() > 0;
    }
}