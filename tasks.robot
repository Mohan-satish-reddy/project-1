*** Settings ***
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             XML
Library             RPA.Robocorp.Vault
Library             RPA.Robocloud.Secrets
Library             RPA.Archive
Library             RPA.Dialogs
Library             Dialogs

*** Tasks ***
Complete the challenge
    Start the challenge
    Fill the forms
    Success dialog
    Create ZIP package from PDF files
    [Teardown]    Log out and Close

*** Keywords ***
Start the challenge
    ${secret}=    RPA.Robocloud.Secrets.Get Secret    robotsparebin
    Open Available Browser    ${secret}[Website]
    Input Text    username    ${secret}[username]
    Input Text    password    ${secret}[password]
    Click Button    Log in
    Go To    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element    xpath://*[@id="root"]/div/div[2]/div/div
    Click Button    OK
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    overwrite=True


Fill the forms
    ${people}=    Get the list of people from the CSV file
    FOR    ${person}    IN    @{people}
        Fill and submit the form    ${person}
    END

Get the list of people from the CSV file
    ${csv}=    Input from dialog
    ${table}=    Read table from CSV    ${csv}   header=True
    RETURN    ${table}

Input from dialog
    Add heading    User Input
    Add text input    csv_file
    ${result}=    Run dialog
    Log    ${result.csv_file}
    IF    "${result.csv_file}" == "orders.csv"
        ${csv}=    Set Variable    orders.csv
        
    ELSE
        ${csv}=    Set Variable    orders.csv
    END
    Return From Keyword If    "${csv}"!=""    ${csv}
Success dialog
    Add icon      Success
    Add heading   Successfully completed all your orders
    Run dialog    title=Success
    

Fill and submit the form
    [Arguments]    ${person}
    Select From List By Value    head    ${person}[Head]
    Wait And Click Button    id-body-${person}[Body]
    Input Text    address    ${person}[Address]
    Input Text    class:form-control    ${person}[Legs]
    Click Button    preview
    Wait Until Page Contains Element    robot-preview
    Sleep    4s
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}sales_scrnshots${/}sales_summary-${person}[Order number].png
    Wait Until Keyword Succeeds    10x    1s    Order
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}sales_results${/}sales_results-${person}[Order number].pdf
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}sales_receipts${/}sales_receipts-${person}[Order number].pdf
    ${PDF}=    Open Pdf    ${OUTPUT_DIR}${/}sales_results${/}sales_results-${person}[Order number].pdf
    ${final}=    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}sales_scrnshots${/}sales_summary-${person}[Order number].png
    ...    ${OUTPUT_DIR}${/}sales_results${/}sales_results-${person}[Order number].pdf
    Close Pdf    ${PDF}
    ${final}=    Create List
    ...    ${OUTPUT_DIR}${/}sales_results${/}sales_results-${person}[Order number].pdf
    Add Files To Pdf    ${final}    ${OUTPUT_DIR}${/}sales_receipts.pdf    append=True
    Click Button    order-another
    Click Button    OK

Order
    Click Button    order
    Wait Until Page Contains Element    receipt

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}sales_receipts.Zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}sales_receipts
    ...    ${zip_file_name}

Confirmation dialog
    Add icon      Warning
    Add heading   Do you wish to Close Browser, the process completed
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        Click Button    logout
        Close Browser
    END

Log out and Close
    Confirmation dialog