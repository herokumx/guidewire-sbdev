global class UserRegionHelper
{
    global static String getCurrentUserDefaultRegion()
    {
        String roleName = null;
        if(UserInfo.getUserRoleId() != null)
        {
            UserRole role =[SELECT Id, Name from UserRole where Id = :UserInfo.getUserRoleId() LIMIT 1];        
            roleName = role.Name;
        
        }
        return getDefaultRegionForRole(roleName);
    }
    
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
                roleName.startsWith('FrIt SC') ||
                roleName.startsWith('UKI')) retval = 'EMEA';

        return retval;
    }

}