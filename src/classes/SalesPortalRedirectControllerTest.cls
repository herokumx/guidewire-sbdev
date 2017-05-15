@isTest
public class SalesPortalRedirectControllerTest 
{
	@isTest
	private static void testRedirect()
	{
		SalesPortalRedirectController ctlr = new SalesPortalRedirectController();
		PageReference redirect = ctlr.redirect();
		System.Assert(redirect.getUrl().contains(SalesPortalRedirectController.PORTAL_HOME));
	}
}