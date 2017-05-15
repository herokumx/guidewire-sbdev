/****************************************************************************************
Name            : psaUtils
Author          : CLD Partners
Created Date    : March 23, 2015
Description     : Contains methods to support PSA Implementation/Operation
Revisions       : 3/23/15 - Initial version
******************************************************************************************/
public class psaUtils {
	public psaUtils() {}

	public static Date getTimecardWeekStartDate(Date inputDate) {
		Date startOfWeekDate;

		// build our 7-day date range between the start of the week and the end of the week
		//  Special logic to handle GW's start day fallin on a Saturday
        startOfWeekDate = inputDate.toStartOfWeek().addDays(-1);

        return startOfWeekDate;
	}

}