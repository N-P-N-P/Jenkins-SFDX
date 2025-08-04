@isTest
private class ContactHandlerTest {
    @isTest
    static void testCreateContact() {
        Contact result = ContactHandler.createContact('John', 'Doe', 'john.doe@example.com');
        System.assertNotEquals(null, result.Id);
        System.assertEquals('John', result.FirstName);
    }

    @isTest
    static void testUpdateEmail() {
        Contact con = new Contact(FirstName='Jane', LastName='Doe', Email='jane.doe@example.com');
        insert con;
        ContactHandler.updateEmail(con.Id, 'new.email@example.com');
        Contact updatedCon = [SELECT Email FROM Contact WHERE Id = :con.Id];
        System.assertEquals('new.email@example.com', updatedCon.Email);
    }
}
