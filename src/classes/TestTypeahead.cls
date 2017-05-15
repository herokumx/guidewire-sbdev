@isTest
public class TestTypeahead {
    static testMethod void testTypeahead() {
        List<String> fieldNames = new List<String>();
        fieldNames.add('AccountNumber');
        Typeahead.searchRecords('Gforce', 'Account', fieldNames, 'NAME', 'RecordType.Name != null', 'Name', 1);
    }
}