*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Variables ***
${DOWNLOAD_PATH}=           ${OUTPUT_DIR}${/}orders.csv
${PDF_FOLDER}=              ${OUTPUT_DIR}${/}pdfs
${SCREENSHOT_FOLDER}=       ${OUTPUT_DIR}${/}screenshots
${ZIP_PATH}=                ${OUTPUT_DIR}${/}zipped_receipts.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${user}=    Ask user's name
    Log user    ${user}
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser


*** Keywords ***
Ask user's name
    Add heading    Please enter your name!
    Add text input    name    label=Name
    ${response}=    Run dialog
    RETURN    ${response.name}

Log user
    [Arguments]    ${user}
    Log    Current user is ${user}.

Open the robot order website
    ${url}=    Get Secret    RobotSpareBinIndustries_Url
    Open Available Browser    ${url}[Url]

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    ${DOWNLOAD_PATH}
    ${output}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    ${DOWNLOAD_PATH}
    RETURN    ${output}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Fill the form for one order
    ...    ${row}[Order number]
    ...    ${row}[Head]
    ...    ${row}[Body]
    ...    ${row}[Legs]
    ...    ${row}[Address]

Fill the form for one order
    [Arguments]    ${Order number}    ${Head}    ${Body}    ${Legs}    ${Address}
    Select From List By Value    head    ${Head}
    Select Radio Button    body    ${Body}
    ${legs_id}=    Get Element Attribute    xpath://*[contains(text(), "3. Legs:")]    for
    Input Text    ${legs_id}    ${Legs}
    Input Text    address    ${Address}

Preview the robot
    Click Button    preview

Submit the order
    WHILE    True    limit=5
        Click Button    order
        TRY
            Wait Until Element Is Visible    receipt    timeout=1 second
            BREAK
        EXCEPT    AS    ${message}
            Log    Receipt didn't open after clicking Order - original exception message: ${message}.
        END
    END

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${output_file}=    Set Variable    ${PDF_FOLDER}${/}${Order number}.pdf
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${output_file}
    RETURN    ${output_file}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    ${output}=    Set variable    ${SCREENSHOT_FOLDER}${/}${Order number}.png
    Screenshot    robot-preview-image    ${output}
    RETURN    ${output}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${file_to_embed}=    Create List    ${screenshot}
    Add Files To Pdf    ${file_to_embed}    target_document=${pdf}    append=True

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${PDF_FOLDER}    ${ZIP_PATH}

Close the browser
    Close Browser
