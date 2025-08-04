public class ContactHandler {
    public static Contact createContact(String firstName, String lastName, String email) {
        Contact con = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email
        );
        insert con;
        return con;
    }

    public static void updateEmail(Id contactId, String newEmail) {
        Contact con = [SELECT Id, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        con.Email = newEmail;
        update con;
    }
}
