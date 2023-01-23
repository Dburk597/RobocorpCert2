
*** Settings ***

Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library    RPA.Browser.Selenium    auto_close=${FALSE}    
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.FileSystem
Library    Dialogs
Library    RPA.Robocorp.Vault

*** Keywords ***

Open browser and close annoying pop-up
    ${secret_url}=    Get Secret    URLs   
    Open Available Browser    ${secret_url}[robotsparebin_url]        #https://robotsparebinindustries.com/#/robot-order - in local vault
    Click Button    xpath://button[contains(text(),"Yep")]


Download the Orders.csv file
    ${user_input_url}=    Get Value From User    Please input the url for the orders.csv file
    Download    ${user_input_url}   target_file=${OUTPUT_DIR}${/}orders.csv    overwrite=True
    #Download    https://robotsparebinindustries.com/orders.csv    target_file=${OUTPUT_DIR}${/}orders.csv    overwrite=True




Fill out form for one person
    [Arguments]    ${robot_part}    
    Wait Until Element Is Visible   head
    Select From List By Index    xpath://select[@id='head']    ${robot_part}[Head]      #xpath://option[contains(text(),'Roll-a-thor head')]        
    Click Element    xpath://input[@id='id-body-${robot_part}[Body]']
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${robot_part}[Legs]
    Input Text    xpath://input[@id='address']    ${robot_part}[Address]
    Wait Until Element Is Enabled    xpath://button[@id='order']
    Click Button    xpath://button[@id='order']



For each CSV row fill out the form
    ${robot_parts}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    header=True
    FOR    ${robot_part}    IN    @{robot_parts}
        Fill out form for one person    ${robot_part}
        ${is_there_an_error}=    Is Element Visible    xpath://div[@class='alert alert-danger']
        IF    ${is_there_an_error} == ${False}
             Save each HTML receipt as a PDF    ${robot_part}
             Take screenshot and embed it into PDF    ${robot_part}
        ELSE    
            Log    Order Submission Error    level=Warn
            CONTINUE    
            
        END
       
    END 
               

Save each HTML receipt as a PDF
    
    [Arguments]    ${robot_part}
    ${receipt_HTML}=    Get Element Attribute    xpath://div[@id='receipt']    outerHTML
    Html To Pdf    ${receipt_HTML}    ${OUTPUT_DIR}${/}Zip${/}receipt${robot_part}[Order number].pdf    overwrite=True 


Take screenshot and embed it into PDF
    [Arguments]    ${robot_part}
    Screenshot    xpath://div[@id='receipt']    ${CURDIR}${/}Screenshots${/}receipt${robot_part}[Order number].png             
    Open Pdf    ${OUTPUT_DIR}${/}Zip${/}receipt${robot_part}[Order number].pdf
    Add Watermark Image To Pdf    ${CURDIR}${/}Screenshots${/}receipt${robot_part}[Order number].png     ${OUTPUT_DIR}${/}Zip${/}receipt${robot_part}[Order number].pdf
    Close Pdf    
    Wait Until Element Is Enabled    xpath://button[@id='order-another']
    Click Button    xpath://button[@id='order-another']  
    Wait Until Element Is Visible    xpath://button[contains(text(),"Yep")]
    Click Button    xpath://button[contains(text(),"Yep")]                                 

Create temporary PDF/screenshots directory
    Create Directory    ${OUTPUT_DIR}${/}Zip    
    Create Directory    ${CURDIR}${/}Screenshots


Remove temporary PDF/screenshots directory
    Remove Directory    ${OUTPUT_DIR}${/}Zip    True    
    Remove Directory    ${CURDIR}${/}Screenshots    True


Archive the stupid zip folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Zip    ${OUTPUT_DIR}${/}PDFs.zip                


*** Tasks ***
Go into Site
    Create temporary PDF/screenshots directory
    Open browser and close annoying pop-up
    Download the Orders.csv file
    For each CSV row fill out the form
    Archive the stupid zip folder
    [Teardown]    Remove temporary PDF/screenshots directory
