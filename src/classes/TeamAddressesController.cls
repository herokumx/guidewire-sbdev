public without sharing class TeamAddressesController {

  public List<User> getFullTeamAddresses()
  {
      List<User> theUsers = [SELECT Id, Name, Street, City, State, Country, PostalCode from User
                             WHERE 
                               IsActive=true AND
                               Street != null
                             ORDER BY Name];
      return theUsers;
  }
    

}