namespace riskmanagement;

using {
    cuid,
    managed
} from '@sap/cds/common';

// Entity risks
entity Risks : cuid, managed {
    //key ID          : UUID @(Core.Computed : true);
    title       : String(100);
    owner       : String;
    prio        : String(5);
    descr       : String;
    miti        : Association to Mitigations;
    impact      : Integer;
    bp          : Association to BusinessPartners;
    criticality : Integer;
}

// mitigations
entity Mitigations : cuid, managed {
    //key ID       : UUID @(Core.Computed : true);
    descr    : String;
    owner    : String;
    timeline : String;
    risks    : Association to many Risks
                   on risks.miti = $self;
}

// using an external service from S/4
using {API_BUSINESS_PARTNER as external} from '../srv/external/API_BUSINESS_PARTNER.csn';

entity BusinessPartners as projection on external.A_BusinessPartner {
    key BusinessPartner, LastName, FirstName
}
