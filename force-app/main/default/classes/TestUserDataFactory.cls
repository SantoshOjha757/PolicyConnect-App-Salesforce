public with sharing class TestUserDataFactory {
    public static User createTestUsers(String firstName, String lastName, String email, String baseUserName, Id profileId, Id roleId) {
        
        User testUser = new User();
        testUser.FirstName = firstName;
        testUser.LastName = lastName;
        testUser.Email = email;
        testUser.Username = baseUserName + DateTime.Now().Time().minute() + '@test.com';
        testUser.Alias = testUser.Username.Substring(0, Math.min(5, baseUserName.length()));
        testUser.TimeZoneSidKey = 'Asia/Kolkata';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_IN';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.ProfileId = profileId;
        testUser.UserRoleId = roleId;

        insert testUser;

        if(testUser != null){
            return testUser;
        }
        return null;
    }
}