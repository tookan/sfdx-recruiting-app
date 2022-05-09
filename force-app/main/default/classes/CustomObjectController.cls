global class CustomObjectController {
  public static final Integer PAGE_SIZE = 50;
  public static final Integer SEARCH_TERM_MIN_LENGTH = 3;

  public static String executeListRecords(
    String searchTerm,
    Integer pageCurrent,
    RequestHelper requestHelper
  ) {
    Integer skipRecordsCount = PAGE_SIZE * (pageCurrent - 1);
    Integer takeRecordsCount = PAGE_SIZE;

    requestHelper.skipRecordsCount = skipRecordsCount;
    requestHelper.takeRecordsCount = takeRecordsCount;
    requestHelper.searchTerm = searchTerm;

    List<SObject> dataResult = new List<SObject>();

    if (searchTerm.length() >= SEARCH_TERM_MIN_LENGTH) {
      dataResult = requestHelper.listRecordsSearch();
    } else {
      dataResult = requestHelper.listRecordsRequest();
    }

    PaginatedResponse responseObject = new PaginatedResponse();
    responseObject.pageCurrent = pageCurrent;
    responseObject.pageTotalCount = Math.round(dataResult.size() / PAGE_SIZE);
    responseObject.pageData = dataResult;

    return JSON.serialize(responseObject);
  }
}
