*** Settings ***
Documentation        Orders robots from RobotSpareBin Industries Inc.
...                  Saves the order HTML receipt as a PDF file.
...                  Saves the screenshot of the ordered robot.
...                  Embeds the screenshot of the robot to the PDF receipt.
...                  Creates ZIP archive of the receipts and the images.

Library            RPA.Browser.Selenium    auto_close=${FALSE}
Library            RPA.HTTP
Library            RPA.Tables
Library            RPA.PDF
Library            RPA.Archive
Library            RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders website
    Download the orders
    Read csv
    Zip receipts
    Remove orders file
    [Teardown]    Close Browser

*** Keywords ***
Open the robot orders website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the modal
    Wait Until Element Is Visible    //button[@class="btn btn-dark"]
    Click Element    //button[@class="btn btn-dark"]

Download the orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Close and start Browser if needed
    Close Browser
    Open the robot orders website
    Continue For Loop

Check if alert div visible
    FOR  ${i}  IN RANGE  ${30}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]
        Run Keyword If  '${alert}'=='True'  Click Button  order
        Exit For Loop If  '${alert}'=='False'
    END

    Run Keyword If  '${alert}'=='True'  Close and start Browser if needed

Fill and submit the form for one order
    [Arguments]    ${row}
    Close the modal
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Wait Until Element Is Visible    order
    Click Button    order

Get receipt and click order another
    [Arguments]  ${row}
    ${sales_results_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipts${/}order_${row}[Order number].pdf
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}order_${row}[Order number].png
    Add Watermark Image To Pdf  ${OUTPUT_DIR}${/}screenshots${/}order_${row}[Order number].png  ${OUTPUT_DIR}${/}receipts${/}order_${row}[Order number].pdf  ${OUTPUT_DIR}${/}receipts${/}order_${row}[Order number].pdf
    Click Button  order-another


Read csv
    ${table}=    Read table from CSV    orders.csv
    FOR    ${row}    IN    @{table}
        Fill and submit the form for one order    ${row}
        Check if alert div visible
        Get receipt and click order another    ${row}
    END

Zip receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts     ${OUTPUT_DIR}${/}receipts.zip

Remove orders file
    Remove File    orders.csv
