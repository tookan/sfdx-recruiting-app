({
    doInit : function(component, event, helper) {
        var apexAction = component.get("c.cancelVacancy");
        apexAction.setParams({recordId: component.get("v.recordId")});

        apexAction.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
        
                this.set("v.isUpdated", true);
               /* window.setTimeout(function(){
                    $A.get('e.force:refreshView').fire();
                }, 1000);*/
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        }.bind(component));

        $A.enqueueAction(apexAction);
    }
})