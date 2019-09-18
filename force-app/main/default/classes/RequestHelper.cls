abstract public class RequestHelper
{
    public Integer skipRecordsCount {get;set;}
    public Integer takeRecordsCount {get;set;}
    public String searchTerm {get;set;}

    public abstract List<SObject> listRecordsRequest();

    public abstract  List<SObject> listRecordsSearch();

    public List<SObject> paginateSearchList(List<SObject> recordsResult){

        Integer recordsResultSize = recordsResult.size();
        List<SObject> result = new List<SObject>();

        for (Integer i = skipRecordsCount; i < skipRecordsCount + CustomObjectController.PAGE_SIZE; i++) {
            if (recordsResultSize > i) {
                result.add(recordsResult.get(i));
            } else break;
        }

        return result;
    }
}