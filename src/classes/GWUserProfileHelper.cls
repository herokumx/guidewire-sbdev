global class GWUserProfileHelper
{
    /*
       00e800000014vg5 GW Presales Management
       00e80000001584R GW Presales
       00e800000014vgt GW Sales
       00e30000000cGt8 Sysadmin
    
    */


    global static Boolean isPresalesManager()
    {
      System.debug('*** isPresalesManager looking at ' + UserInfo.getProfileId());
       return UserInfo.getProfileId().startsWith('00e800000014vg5') ||
              UserInfo.getProfileId().startsWith('00e30000000cGt8');
    }

    global static Boolean isPresales()  // Basic Presales User and Presales Manager
    {
        return UserInfo.getProfileId().startsWith('00e800000014vg5') ||
               UserInfo.getProfileId().startsWith('00e80000001584R') ||
               UserInfo.getProfileId().startsWith('00e30000000cGt8');


    }  
    
    global static Boolean isSales()
    {
       return UserInfo.getProfileId().startsWith('00e800000014vgt') ||
              UserInfo.getProfileId().startsWith('00e80000001Wf1A');
    }

    global static Boolean isSysAdmin()
    {
       return UserInfo.getProfileId().startsWith('00e30000000cGt8');
    }
    
      
    /*
    global static String getDefaultRegionForRole(String roleName)
    {    
        String retval = 'AMER';
        if(roleName == null) return retval;
        
        //RoleSTARTS WITHNorth American,The Americas,NA = AMER
        //RoleSTARTS WITHInternational-AP,AP,ANZ,Japan = APAC
        //RoleSTARTS WITHInternational-EMEA,EMEA,FrBe,N Europe,DACH,S Europe,UKI = EMEA
        if(roleName.startsWith('North American') ||
           roleName.startsWith('The Americas') ||
           roleName.startsWith('NA')) retval = 'AMER';
           
        else if(roleName.startsWith('International-AP') ||
                roleName.startsWith('AP') ||
                roleName.startsWith('ANZ') ||
                roleName.startsWith('Japan')) retval = 'APAC';
           
        else if(roleName.startsWith('International-EMEA') ||
                roleName.startsWith('EMEA') ||
                roleName.startsWith('FrBe') ||
                roleName.startsWith('N Europe') ||
                roleName.startsWith('DACH') ||
                roleName.startsWith('S Europe') ||
                roleName.startsWith('UKI')) retval = 'EMEA';

        return retval;
    }
   */
}