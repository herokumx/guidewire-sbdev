/**
 * trac_TestValidData
 * @Description: test data validator
 * @Author: kJ - Traction On Demand
 * @Date: 2015-Mar-24
 */
 @isTest
public class trac_TestValidData {

	/*************************************************
     *  Public Methods
     ************************************************/
	public TestData getType(System.Type sobjectType) {
		Map<String,System.Type> testDataSObjectMapping = getTestDataSObjectMapping();
		System.Type testDataType = testDataSObjectMapping.get(sobjectType.getName());
		if(testDataType != null)
			return (TestData) testDataType.newInstance();
		else
			return new TestData();

	}

	/*************************************************
     *  Private Methods
     ************************************************/

	private Map<String,System.Type> getTestDataSObjectMapping() {
		Map<String,System.Type> result = new Map<String,System.Type> {
			Contact.class.getName()                => ContactsTestData.class
		};
		return result;
	}

	/***************************************************************** Abstract TestData Class ******************************************************/
	
	public virtual class TestData {
		public List<SObject> makeValid(List<SObject> records) {
			List<SObject> result = new List<SObject>();
			for(SObject record :records) {
				result.add(
					makeValid(record)
				);
			}
			return result;
		}

		public virtual SObject makeValid(SObject record) {
			return record;
		}
	}
	
	/***************************************************************** TestData Class for Contact ******************************************************/
	
	class ContactsTestData extends TestData {
		public override SObject makeValid(SObject record) {
			Contact aContact = (Contact) record;
			if(String.isBlank(aContact.LastName))
				aContact.LastName = 'LastName';
			return aContact;
		}
	}
}