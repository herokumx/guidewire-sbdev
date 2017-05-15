public with sharing class SalesPortalRedirectController {
	public static final String PORTAL_HOME = '/apex/cms__Main?sname=Sales_Portal';
	public PageReference redirect()	{ return new PageReference(PORTAL_HOME); }
}