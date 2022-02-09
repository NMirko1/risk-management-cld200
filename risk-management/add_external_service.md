# Add an External Service to Your CAP Service

In this part, you will extend your CAP service with the consumption of an external Business Partner service.

## Learning objectives

- Search for a service on SAP's API Business Hub
- Download an Entity Data Model XML (EDMX) file of the external service definition from SAP's API Business Hub.
- Add an <a href="http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part3-csdl.html" target="_blank">EDMX</a><sup>1</sup> file to your project.
- Consume an External Service in a UI Application

## Prerequisites

You have added custom business logic to your extension.

## Download the Business Partner EDMX File

1. Open the [SAP API Business Hub](https://api.sap.com/)<sup>2</sup> page in your browser
2. Type "Business Partner A2X" into the page's search field and carry out the search
3. In the result list, choose `Business Partner (A2X)`
4. Choose the first API with the `Found in: SAP S/4HANA Sandbox` information on the right upper corner of this API.

   ![API Details](images/01_03_0030.png)

5. Under Document, choose the `API Specification` button.
6. Choose the `EDMX` option from the list and click the download button (if you’re asked to log on, log on using your SAP user)

   ![API EDMX](images/01_03_0040.png)

## Add the EDMX File to the Project

1. Ensure in your terminal `cds watch` is still running
2. Drag the `API_BUSINESS_PARTNER.edmx` file from your browser's download area/folder onto your Business Application Studio workplace and drop it into the `srv` folder of your `risk-management` app.

   CAP has noticed the new file and automatically created a new `external` folder under `srv` and in it added a new `API_BUSINESS_PARTNER.csn` file. ([capire](https://cap.cloud.sap/docs/cds/csn)<sup>3</sup> is a compact representation of CDS).

3. In your project, open the `db/schema.cds` file and enter the code listed below between `//### BEGIN OF INSERT` and `//### END OF OF INSERT`.

   ```javascript
   namespace riskmanagement;

   using {managed} from '@sap/cds/common';

   entity Risks : managed {
       key ID          : UUID @(Core.Computed : true);
           title       : String(100);
           owner       : String;
           prio        : String(5);
           descr       : String;
           miti        : Association to Mitigations;
           impact      : Integer;
           //bp          : Association to BusinessPartners;
           criticality : Integer;
   }

   entity Mitigations : managed {
       key ID       : UUID @(Core.Computed : true);
           descr    : String;
           owner    : String;
           timeline : String;
           risks    : Association to many Risks
                       on risks.miti = $self;
   }

   //### BEGIN OF INSERT

   // using an external service from S/4
   using {  API_BUSINESS_PARTNER as external } from '../srv/external/API_BUSINESS_PARTNER.csn';

   entity BusinessPartners as projection on external.A_BusinessPartner {
       key BusinessPartner,
       LastName,
       FirstName
   }

   //### END OF OF INSERT
   ```

   With this code you create a so-called projection for your new service. Of the many entities and properties in these entities, that are defined in the `API_BUSINESS_PARTNER` service, you just look at one of the entities (`A_BusinessPartner`) and just three of its properties: `BusinessPartner`, `LastName`, and `FirstName`, so your projection is using a subset of everything the original service has to offer.

4. Open the `srv/risk-service.cds` file

5. Uncomment the `entity BusinessPartners` line

   ```javascript
   using {riskmanagement as rm} from '../db/schema';

   /**
    * For serving end users
    */
   service RiskService @(path : 'service/risk') {
       entity Risks as projection on rm.Risks;
       annotate Risks with @odata.draft.enabled;
       entity Mitigations as projection on rm.Mitigations;
       annotate Mitigations with @odata.draft.enabled;
       entity BusinessPartners as projection on rm.BusinessPartners;
   }
   ```

6. Your SAP Fiori elements app should still be running in your web browser. Select the SAP icon on the left upper corner to navigate back to the index page. Hit refresh in your browser. Now press on the **Risks** tile and in the application press **Go**

   The browser now shows a `BusinessPartner` service next to the `Mitigations` and `Risks`

   ![BPService](images/01_03_0050.png)

## Connect your App with the Business Partner API Sandbox Environment of the SAP API Business Hub

At this point, you have a new service exposed with a definition based on the original `edmx` file. However, it doesn't have any connectivity to a backend and thus, there’s no data yet. In this case, you do not create local data as with your `risks` and `mitigations` entities, but you connect your service to the Sandbox environment of the SAP API Business Hub for the Business Partner API that you want to use. To use the API Business Hub Sandbox APIs, you require an API key.

1. Go back to the [SAP API Business Hub](https://api.sap.com/) page in your browser
2. Make sure to be logged in. If not, press the **Log On** button on the upper right (use the SAP user that you also used to create your BTP trial account for the Log On)

   ![Hub Log On](images/08_0010.png)

3. Again, navigate to the Business Partner API (`SAP S/4HANA Cloud` -> `Business Partner (A2X)`)
4. In the right upper corner, choose **Show API Key** to see your API key.

   ![Show API Key](images/08_0020.png)

5. Copy the API key.

   ![Show API Key](images/08_0030.png)

6. In your project in Business Application Studio, create the file `.env` in the `root` of the project (next to files `package.json`, `README.md` etc.). Copy the following line into the file and replace `<YOUR-API-KEY>` with the API key that you copied in the previous step.

   ```bash
   apikey=<YOUR-API-KEY>
   ```

   The result should look like the following:

   ![.env file](images/08_0040.png)

   The `.env` file is an environment file providing values into the runtime environment of your CAP service. You are going to use the API key to call the Business Partner API in the API Business Hub Sandbox environment.

7. By mentioning the `.env` file in the `.gitignore` file you make sure, that when you are using git as a version-management-system for your project, no credentials get accidentally leaked into your potentially public git repository.

   To add `.env` to the `.gitignore` file, execute the following command in a new terminal:

   ```shell
   echo '.env' >> .gitignore
   ```

   You can verify that the `.env` has been added with the command:

   ```shell
   cat .gitignore
   ```

   ![.gitignore file](images/08_0050.png)

8. Open the `package.json` file and add the following lines between `//### BEGIN OF INSERT` and `//### END OF OF INSERT`:

   ```json
   "cds": {
       "requires": {
           "API_BUSINESS_PARTNER": {
               "kind": "odata",
               "model": "srv/external/API_BUSINESS_PARTNER",
               //### BEGIN OF INSERT
               "credentials": {
                   "url": "https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/"
               }
               //### End OF INSERT
           }
       }
   }
   ```

   Now that you have set all the configurations for the external call, you willimplement a custom service handler for the external BusinessPartner service in the next step.

9. Open the `risk-service.js` file and insert the following lines between `//### BEGIN OF INSERT` and `//### END OF OF INSERT`:

   ```javascript
   // Imports
   const cds = require("@sap/cds");

   /**
    * The service implementation with all service handlers
    */
   module.exports = cds.service.impl(async function () {
     // Define constants for the Risk and BusinessPartners entities from the risk-service.cds file
     const { Risks, BusinessPartners } = this.entities;

     /**
      * Set criticality after a READ operation on /risks
      */
     this.after("READ", Risks, (data) => {
       const risks = Array.isArray(data) ? data : [data];

       risks.forEach((risk) => {
         if (risk.impact >= 100000) {
           risk.criticality = 1;
         } else {
           risk.criticality = 2;
         }
       });
     });

     //### BEGIN OF INSERT

     // connect to remote service
     const BPsrv = await cds.connect.to("API_BUSINESS_PARTNER");

     /**
      * Event-handler for read-events on the BusinessPartners entity.
      * Each request to the API Business Hub requires the apikey in the header.
      */
     this.on("READ", BusinessPartners, async (req) => {
       // The API Sandbox returns alot of business partners with empty names.
       // We don't want them in our application
       req.query.where("LastName <> '' and FirstName <> '' ");

       return await BPsrv.transaction(req).send({
         query: req.query,
         headers: {
           apikey: process.env.apikey,
         },
       });
     });
     //### END OF INSERT
   });
   ```

   You've now created a custom handler for your service. This time it called `on` for the `READ` event.

   The handler is invoked when your `BusinessPartner` service is called for a read, so whenever there’s a request for business partner data, this handler is called. It ensures the request for the business partner is directed to the external business partner service. Furthermore, you have added a where clause to the request, which selects only business partners where the first and last name is set.

10. Save the file

11. In your browser, open the `BusinessPartners` link to see the data.

    ![API EDMX](images/01_03_0020.png)

##

# Consume the External Service in Your UI Application

In this chapter, you incorporate the external service into the UI application.

1. Open the `db/data/schema.cds` file
2. Uncomment the `bp` property

   ```javascript
   namespace riskmanagement;

   using {managed} from '@sap/cds/common';

   entity Risks : managed {
       key ID          : UUID @(Core.Computed : true);
           title       : String(100);
           owner       : String;
           prio        : String(5);
           descr       : String;
           miti        : Association to Mitigations;
           impact      : Integer;
           bp          : Association to BusinessPartners; // <-- uncomment this
           criticality : Integer;
   }

   entity Mitigations : managed {
       key ID       : UUID @(Core.Computed : true);
           descr    : String;
           owner    : String;
           timeline : String;
           risks    : Association to many Risks
                       on risks.miti = $self;
   }

   // using an external service from S/4
   using {API_BUSINESS_PARTNER as external} from '../srv/external/API_BUSINESS_PARTNER.csn';

   entity BusinessPartners as projection on external.A_BusinessPartner {
       key BusinessPartner, FirstName, LastName,
   }
   ```

   As you got a new property in your entity, you need to add data for this property in the local data file that you've created before for the `risk` entity.

3. Open the file `riskmanagement-Risks.csv` in your `db/data` folder
4. Replace the content with the new content below which additionally includes the BP data

   ```csv
   ID;createdAt;createdBy;title;owner;prio;descr;miti_id;impact;bp_BusinessPartner
   20466922-7d57-4e76-b14c-e53fd97dcb11;2019-10-24;SYSTEM;CFR non-compliance;Fred Fish;3;Recent restructuring might violate CFR code 71;20466921-7d57-4e76-b14c-e53fd97dcb11;10000;9980000448
   20466922-7d57-4e76-b14c-e53fd97dcb12;2019-10-24;SYSTEM;SLA violation with possible termination cause;George Gung;2;Repeated SAL violation on service delivery for two successive quarters;20466921-7d57-4e76-b14c-e53fd97dcb12;90000;9980002245
   20466922-7d57-4e76-b14c-e53fd97dcb13;2019-10-24;SYSTEM;Shipment violating export control;Herbert Hunter;1;Violation of export and trade control with unauthorized downloads;20466921-7d57-4e76-b14c-e53fd97dcb13;200000;9980000230
   ```

5. Save the file

If you check the content of the file, you see numbers like `9980000230` at the end of the lines, representing business partners.

## Add the Business Partner Field to the UI

You need to introduce the business partner field in the UI:

- Add a label for the columns in the result list table as well as in the object page by adding a title annotation
- Add the business partner as a line item to include it as a column in the result list
- Add the business partner as a field to a field group, which makes it appear in a form on the object page

All this happens in the cds file that has all the UI annotations. Enter the code between `//### BEGIN OF INSERT` and `//### END OF OF INSERT`.

1. Open the `app/common.cds` file
2. Insert the following parts:

   ```javascript
   using riskmanagement as rm from '../db/schema';

   // Annotate Risk elements
   annotate rm.Risks with {
       ID          @title : 'Risk';
       title       @title : 'Title';
       owner       @title : 'Owner';
       prio        @title : 'Priority';
       descr       @title : 'Description';
       miti        @title : 'Mitigation';
       impact      @title : 'Impact';
       //### BEGIN OF INSERT
       bp          @title : 'Business Partner';
       //### END OF INSERT
       criticality @title : 'Criticality';
   }

   // Annotate Miti elements
   annotate rm.Mitigations with {
       ID    @(
           UI.Hidden,
           Commong : {Text : descr}
       );
       owner @title : 'Owner';
       descr @title : 'Description';
   }

   //### BEGIN OF INSERT
   annotate rm.BusinessPartners with {
       BusinessPartner @(
           UI.Hidden,
           Common : {Text : LastName}
       );
       LastName        @title : 'Last Name';
       FirstName       @title : 'First Name';
   }
   //### END OF INSERT

   annotate rm.Risks with {
       miti @(Common : {
           //show text, not id for mitigation in the context of risks
           Text            : miti.descr,
           TextArrangement : #TextOnly,
           ValueList       : {
               Label          : 'Mitigations',
               CollectionPath : 'Mitigations',
               Parameters     : [
                   {
                       $Type             : 'Common.ValueListParameterInOut',
                       LocalDataProperty : miti_ID,
                       ValueListProperty : 'ID'
                   },
                   {
                       $Type             : 'Common.ValueListParameterDisplayOnly',
                       ValueListProperty : 'descr'
                   }
               ]
           }
       });
       //### BEGIN OF INSERT
       bp   @(Common : {
           Text            : bp.LastName,
           TextArrangement : #TextOnly,
           ValueList       : {
               Label          : 'Business Partners',
               CollectionPath : 'BusinessPartners',
               Parameters     : [
                   {
                       $Type             : 'Common.ValueListParameterInOut',
                       LocalDataProperty : bp_BusinessPartner,
                       ValueListProperty : 'BusinessPartner'
                   },
                   {
                       $Type             : 'Common.ValueListParameterDisplayOnly',
                       ValueListProperty : 'LastName'
                   },
                   {
                       $Type             : 'Common.ValueListParameterDisplayOnly',
                       ValueListProperty : 'FirstName'
                   }
               ]
           }
       })
   //### END OF INSERT
   }
   ```

3. Open the `app/risk/annotations.cds` file and insert the following lines between `//### BEGIN OF INSERT` and `//### END OF OF INSERT`:

   ```javascript
   using RiskService from '../../srv/risk-service';

   // Risk List Report Page
   annotate RiskService.Risks with @(UI : {
       HeaderInfo      : {
           TypeName       : 'Risk',
           TypeNamePlural : 'Risks',
           Title          : {
               $Type : 'UI.DataField',
               Value : title
           },
           Description    : {
               $Type : 'UI.DataField',
               Value : descr
           }
       },
       SelectionFields : [prio],
       Identification  : [{Value : title}],
       // Define the table columns
       LineItem        : [
           {Value : title},
           {Value : miti_ID},
           {Value : owner},
           //### BEGIN OF INSERT
           {Value : bp_BusinessPartner},
           //### END OF INSERT
           {
               Value       : prio,
               Criticality : criticality
           },
           {
               Value       : impact,
               Criticality : criticality
           },
       ],
   });

   // Risk Object Page
   annotate RiskService.Risks with @(UI : {
       Facets           : [{
           $Type  : 'UI.ReferenceFacet',
           Label  : 'Main',
           Target : '@UI.FieldGroup#Main',
       }],
       FieldGroup #Main : {Data : [
           {Value : miti_ID},,
           {Value : owner},
           //### BEGIN OF INSERT
           {Value : bp_BusinessPartner},
           //### END OF INSERT
           {
               Value       : prio,
               Criticality : criticality
           },
           {
               Value       : impact,
               Criticality : criticality
           }
       ]},
   });

   ```

   What does the code do? The first part enables the title and add the business partner first as a column to the list and then as a field to the object page, just like other columns and fields were added before.

   The larger part of new annotations activates the same qualities for the `bp` field as it happened before in [Create a CAP-Based Service](course_content\01_Basics\Create_a_CAP-Based_Service)<sup>4</sup> for the `miti` field: Instead of showing the ID of the business partner, its `LastName` property is displayed. The `ValueList` part introduces a value list for the business partner and shows it last and first name in it.

4. Save the file
5. Open the `srv/risk-service.js` file
6. Add the following lines between `//### BEGIN OF INSERT` and `//### END OF OF INSERT` to the file:

   ```javascript
   // Imports
   const cds = require("@sap/cds");

   /**
    * The service implementation with all service handlers
    */
   module.exports = cds.service.impl(async function () {
     // Define constants for the Risk and BusinessPartners entities from the risk-service.cds file
     const { Risks, BusinessPartners } = this.entities;

     /**
      * Set criticality after a READ operation on /risks
      */
     this.after("READ", Risks, (data) => {
       const risks = Array.isArray(data) ? data : [data];

       risks.forEach((risk) => {
         if (risk.impact >= 100000) {
           risk.criticality = 1;
         } else {
           risk.criticality = 2;
         }
       });
     });

     // connect to remote service
     const BPsrv = await cds.connect.to("API_BUSINESS_PARTNER");

     /**
      * Event-handler for read-events on the BusinessPartners entity.
      * Each request to the API Business Hub requires the apikey in the header.
      */
     this.on("READ", BusinessPartners, async (req) => {
       // The API Sandbox returns alot of business partners with empty names.
       // We don't want them in our application
       req.query.where("LastName <> '' and FirstName <> '' ");

       return await BPsrv.transaction(req).send({
         query: req.query,
         headers: {
           apikey: process.env.apikey,
         },
       });
     });

     //### BEGIN OF INSERT

     /**
      * Event-handler on risks.
      * Retrieve BusinessPartner data from the external API
      */
     this.on("READ", Risks, async (req, next) => {
       /*
           Check whether the request wants an "expand" of the business partner
           As this is not possible, the risk entity and the business partner entity are in different systems (SAP BTP and S/4 HANA Cloud),
           if there is such an expand, remove it
           */
       const expandIndex = req.query.SELECT.columns.findIndex(
         ({ expand, ref }) => expand && ref[0] === "bp"
       );
       console.log(req.query.SELECT.columns);
       if (expandIndex < 0) return next();

       req.query.SELECT.columns.splice(expandIndex, 1);
       if (
         !req.query.SELECT.columns.find((column) =>
           column.ref.find((ref) => ref == "bp_BusinessPartner")
         )
       ) {
         req.query.SELECT.columns.push({ ref: ["bp_BusinessPartner"] });
       }

       /*
           Instead of carrying out the expand, issue a separate request for each business partner
           This code could be optimized, instead of having n requests for n business partners, just one bulk request could be created
           */
       try {
         const res = await next();
         await Promise.all(
           res.map(async (risk) => {
             const bp = await BPsrv.transaction(req).send({
               query: SELECT.one(this.entities.BusinessPartners)
                 .where({ BusinessPartner: risk.bp_BusinessPartner })
                 .columns(["BusinessPartner", "LastName", "FirstName"]),
               headers: {
                 apikey: process.env.apikey,
               },
             });
             risk.bp = bp;
           })
         );
       } catch (error) {}
     });
     //### END OF INSERT
   });
   ```

   You have added another custom handler, this one is called `on` a `READ` of the `Risks` service. It checks whether the request includes a so-called expand for business partners. This is a request that is issued by the UI when the list should be filled. While it mostly contains columns that directly belong to the `Risks` entity, it also contains the business partner. As we have seen in the annotation file, instead of showing the ID of the business partner, the last name of the business partner will be shown. This data is in the business partner and not in the risks entity. Therefore, the UI wants to expand, i.e., for each risk the corresponding business partner is also read.

   As the business partner does not reside in the CAP database but in a remote system instead, a direct expand is not possible. The data needs to be retrieved from the S/4HANA Cloud system.

7. Save the file
8. In your tab with the application, go back to the **index.html** page and press refresh

9. On the launch page that now comes up, choose the **Risks** tile and then click **Go**

   You now see the `Risks` application with the business partner data in both the result list and the object page, which is loaded when you click on one of the rows in the table:

   ![Business Partner Data](images/01_04_0010.png "Business Partner Data")

   When you are on the object page, press the **Edit** button on the top right of the screen. Now you can use the value help for the _Business Partner_ field and search for other Business Partners, which are provided via the Business Partner API.

   ![Business Partner Data](images/01_04_0020.png "Business Partner Data")

## Summary

You have added an external business partner service to your application. The last step is to deploy your application manually.

## Reference links
For your convenience this section contains the external references of this lesson in the following format:

- Reference number
- Section heading
- Context text fragment to identify the location in the section
- Brief description of the linked content
- Link to the content as link and in clear text.

If links are used multiple times in a text, only the first location is mentioned in the reference table.

Ref#|Section|Context text fragment|Brief description|Link
----|-------|---------------------|-----------------|------
1|Learning objectives|Add an EDMX file to your project.| EDMX OData standard |[http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part3-csdl.html](http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part3-csdl.html)
2|Download the Business Partner EDMX File|Open the SAP API Business Hub page |SAP API Business Hub|[https://api.sap.com/](https://api.sap.com/)
3|Add the EDMX File to the Project|as it happened before in Create a CAP-Based Service |SAP Cloud Application Programming Model|[https://cap.cloud.sap/docs/cds/csn](https://cap.cloud.sap/docs/cds/csn)
4|Add the Business Partner Field to the UI|capire is a compact representation of CDS |SAP Cloud Application Programming Model|[https://cap.cloud.sap/docs/cds/csn](https://cap.cloud.sap/docs/cds/csn)



## Code snippets

### Add code to `db/schema.cds`
```javascript
   // using an external service from S/4
   using {  API_BUSINESS_PARTNER as external } from '../srv/external/API_BUSINESS_PARTNER.csn';

   entity BusinessPartners as projection on external.A_BusinessPartner {
       key BusinessPartner,
       LastName,
       FirstName
   }
```

### Add code to `package.json`
```javascript
               "credentials": {
                   "url": "https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/"
               }
```  

### Add code to `risk-service.js` 
```javascript
     // connect to remote service
     const BPsrv = await cds.connect.to("API_BUSINESS_PARTNER");

     /**
      * Event-handler for read-events on the BusinessPartners entity.
      * Each request to the API Business Hub requires the apikey in the header.
      */
     this.on("READ", BusinessPartners, async (req) => {
       // The API Sandbox returns alot of business partners with empty names.
       // We don't want them in our application
       req.query.where("LastName <> '' and FirstName <> '' ");

       return await BPsrv.transaction(req).send({
         query: req.query,
         headers: {
           apikey: process.env.apikey,
         },
       });
     });

```  

### Replace content of `riskmanagement-Risks.csv` with the data below.

   ```csv
   ID;createdAt;createdBy;title;owner;prio;descr;miti_id;impact;bp_BusinessPartner
   20466922-7d57-4e76-b14c-e53fd97dcb11;2019-10-24;SYSTEM;CFR non-compliance;Fred Fish;3;Recent restructuring might violate CFR code 71;20466921-7d57-4e76-b14c-e53fd97dcb11;10000;9980000448
   20466922-7d57-4e76-b14c-e53fd97dcb12;2019-10-24;SYSTEM;SLA violation with possible termination cause;George Gung;2;Repeated SAL violation on service delivery for two successive quarters;20466921-7d57-4e76-b14c-e53fd97dcb12;90000;9980002245
   20466922-7d57-4e76-b14c-e53fd97dcb13;2019-10-24;SYSTEM;Shipment violating export control;Herbert Hunter;1;Violation of export and trade control with unauthorized downloads;20466921-7d57-4e76-b14c-e53fd97dcb13;200000;9980000230
   ```

### Add code to `app/common.cds` 
```javascript
       bp          @title : 'Business Partner';
```

```javascript
   annotate rm.BusinessPartners with {
       BusinessPartner @(
           UI.Hidden,
           Common : {Text : LastName}
       );
       LastName        @title : 'Last Name';
       FirstName       @title : 'First Name';
   }
```

```javascript
       bp   @(Common : {
           Text            : bp.LastName,
           TextArrangement : #TextOnly,
           ValueList       : {
               Label          : 'Business Partners',
               CollectionPath : 'BusinessPartners',
               Parameters     : [
                   {
                       $Type             : 'Common.ValueListParameterInOut',
                       LocalDataProperty : bp_BusinessPartner,
                       ValueListProperty : 'BusinessPartner'
                   },
                   {
                       $Type             : 'Common.ValueListParameterDisplayOnly',
                       ValueListProperty : 'LastName'
                   },
                   {
                       $Type             : 'Common.ValueListParameterDisplayOnly',
                       ValueListProperty : 'FirstName'
                   }
               ]
           }
       })
```

### Add code to `app/risk/annotations.cds`

```javascript
           {Value : bp_BusinessPartner},
```

### Add code to `srv/risk-service.js` 

```javascript

     /**
      * Event-handler on risks.
      * Retrieve BusinessPartner data from the external API
      */
     this.on("READ", Risks, async (req, next) => {
       /*
           Check whether the request wants an "expand" of the business partner
           As this is not possible, the risk entity and the business partner entity are in different systems (SAP BTP and S/4 HANA Cloud),
           if there is such an expand, remove it
           */
       const expandIndex = req.query.SELECT.columns.findIndex(
         ({ expand, ref }) => expand && ref[0] === "bp"
       );
       console.log(req.query.SELECT.columns);
       if (expandIndex < 0) return next();

       req.query.SELECT.columns.splice(expandIndex, 1);
       if (
         !req.query.SELECT.columns.find((column) =>
           column.ref.find((ref) => ref == "bp_BusinessPartner")
         )
       ) {
         req.query.SELECT.columns.push({ ref: ["bp_BusinessPartner"] });
       }

       /*
           Instead of carrying out the expand, issue a separate request for each business partner
           This code could be optimized, instead of having n requests for n business partners, just one bulk request could be created
           */
       try {
         const res = await next();
         await Promise.all(
           res.map(async (risk) => {
             const bp = await BPsrv.transaction(req).send({
               query: SELECT.one(this.entities.BusinessPartners)
                 .where({ BusinessPartner: risk.bp_BusinessPartner })
                 .columns(["BusinessPartner", "LastName", "FirstName"]),
               headers: {
                 apikey: process.env.apikey,
               },
             });
             risk.bp = bp;
           })
         );
       } catch (error) {}
     });
```