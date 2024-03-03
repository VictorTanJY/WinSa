############ Start of Background Code ########################
### HTML reading (Identify errors) and remediation
Function StartAssessment(){
    $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Assement Started `r`n"'
    Invoke-Expression $Expression

    # ##Start-Process powershell -Verb runAs
    ###Set-ExecutionPolicy RemoteSigned
    ##Directory Change
    ##$HTMLFile=$global:HTMLFile ###directory of CIS benchmark
    $FormattedString=''
    $Global:HTMLResults=Get-Content $global:HTMLFile ##-raw makes it into an object

    ######## Normal Functions ##
    function RemoveFrontSpaces($InputValue){
        $FrontSpaceGone="False"
        $InputLengtht=$InputValue.Length
        for($index=0;$index -lt $InputLengtht;$index++){
            if (($FrontSpaceGone -eq "False") -and ($InputValue[$index] -eq " ")){
                ##Skipping the spaces at the front of the html code
            }
            else {
                $FrontSpaceGone="True"
                $FormattedString+=$InputValue[$index]
            }
        }
        if ($FormattedString -match "&amp;"){
            $FormattedString -replace "&amp;", "&"
        }
        return $FormattedString
    }

    ### Filter Register Keys (Only same section)
    
    
    ### Short for loop to gather pass fail error and unknown
    Function ReadFile{
        function LinkDetail($InputValue){
            $tempArray=""
            $tempArray=@()
            $FailTestNumber=$InputValue[0]
            $FailTestDetail=$InputValue[1]
    
            for ($i=0;$i -lt $FailTestNumber.Length;$i++){
                $tempLoopArray=""
                $tempLoopArray=@()
                # $tempLoopItem=$FailTestNumber[$i] -split " "  ### Get 1.1.1 instead of full title
                # $tempLoopArray+=$tempLoopItem[0] 
    
                $tempLoopArray+=$FailTestNumber[$i]  ### Check number
                $tempLoopArray+=$FailTestDetail[$i] ### Fail test details
    
                $tempArray+=$tempLoopArray
            }
            return $tempArray
        }
        function RemoveFrontSpaces($InputValue){
            $FrontSpaceGone="False"
            $InputLengtht=$InputValue.Length
            for($index=0;$index -lt $InputLengtht;$index++){
                if (($FrontSpaceGone -eq "False") -and ($InputValue[$index] -eq " ")){
                    ##Skipping the spaces at the front of the html code
                }
                else {
                    $FrontSpaceGone="True"
                    $FormattedString+=$InputValue[$index]
                }
            }
            if ($FormattedString -match "&amp;"){
                $FormattedString -replace "&amp;", "&"
            }
            return $FormattedString
        }


        $PassFail=$False
        $First4=''
        $TempArray=''
        $CISLength=$Global:HTMLResults.Length
        for ($i=0;$i -lt $CISLength;$i++){#$CISLength
            $LoopString=$Global:HTMLResults[$i]
            ### Pass fail error and unknown
            if($LoopString -match '</tr>'){
                $PassFail=$False
            }
            ### Get all the pass, fail, error and unknown
            if (($PassFail) -and ($First4 -lt 5)){
                $ObtainNum=$LoopString
                $ObtainNum=$ObtainNum.split('<') 
                $ObtainNum=$ObtainNum[1]
                $ObtainNum=$ObtainNum.split(">")
                $ObtainNum=$ObtainNum[1]
                $TempArray+=[int]$ObtainNum
                $First4+=1
            }
            ### After adding the pass, fail, error and unknown for a secion, add it to the Global:ArrayofArrays
            if($First4 -eq 4){
                $LastIndex=$TempArray[0]
                $LastIndex=$LastIndex.split(" ")
                $LastIndex=$LastIndex[0] # 
                if ($LastIndex -eq 9){
                    $TempPass=[int]$TempArray[2]
                    $TempWrong=[int]$TempArray[3]
                    $TempError=[int]$TempArray[4]
                    $TempUnknown= (26 - $TempPass - $TempWrong - $TempError)
                    $TempArray[0]+= " Security)"
                    $TempArray[1] = $TempPass
                    $TempArray[2] = $TempWrong
                    $TempArray[3] = $TempError
                    $TempArray[4] = $TempUnknown
                }
                if (($LastIndex -eq 1) -or ($LastIndex -eq 2) -or ($LastIndex -eq 5) -or ($LastIndex -eq 9) -or ($LastIndex -eq 17) -or ($LastIndex -eq 18) -or ($LastIndex -eq 19)){
                    $Global:ArrayOfArrays+=$TempArray
                }
            }

            ####Get title of section
            if ($LoopString -match 'class="group  sub0"'){
                $TempArray=""
                $TempArray=@()

                $TempString=$LoopString.split('<')
                $TempString1=$TempString[1]
                $TempString1=$TempString1.split('>')
                $TempString1=$TempString1[1]

                $TempString2=$TempString[2]
                $TempString2=$TempString2.Split('>')
                $TempString2=$TempString2[1]

                $TempString1+=$TempString2
                $TempArray+=$TempString1
                # Write-Host $TempArray

                $PassFail=$True
                $First4=0
            }

            #### Too avoid wasting time, the code is design to immediately break after getting all sections
            if ($LastIndex -eq 19){
                break
            }
            ### end of pass fail error and unknown
        }


        $FailTestArray=""
        $FailTestArray=@()
        $FailTestDetail=""
        $FailTestDetail=@()
        $TitleFound="False"
        $FailFound="False"
        $FormattedString=""
        $SentenceStructure=""
        
        $CISLength=$Global:HTMLResults.Length
        for ($i=0;$i -lt $CISLength;$i++){#$CISLength
            $LoopString=$Global:HTMLResults[$i]   

            ###'<table id="assessmentResultTable" width="100%">'
            ### <tr class=" is the html code that we are searching for. 'nonFailureArea' are tests that pass. '<tr class="evaluated">' is not required here
            if (($LoopString -match '<tr class="') -and ($LoopString -notmatch 'nonFailureArea') -and ($LoopString -notmatch '<tr class="evaluated">') -and ($FailFound -eq "False")){
                
                $FailFound="True"
                
            } ###<td><a href="#detail-d1e52700">1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'</a></td>
            if ($FailFound -eq "True"){ ### <td><a start of Title. </a></td> is end of title
                $FormattedString=RemoveFrontSpaces($LoopString)
                if ($LoopString -match '<td><a'){
                    $TitleFound="True"
                    $GreaterThanSignCount=0 ###start to obtain title after 2 ">"
                    $HrefTag="False"
                    $LoopDetailInfo=""
                    for ($x=0;$x -lt $FormattedString.Length;$x++){
                        if ($FormattedString[$x] -eq ">"){
                            $GreaterThanSignCount+=1
                        }
                        elseif($GreaterThanSignCount -eq 2){
                            if ($FormattedString[$x] -ne "<"){
                                $SentenceStructure+=$FormattedString[$x]
                            }
                            else{
                                # $FailTestArray+=$SentenceStructure
                                # $SentenceStructure=''
                                # $FailFound="False"
                                break
                            }
                        }
                        ### Get detail- from html file
                        elseif (($FormattedString[$x] -eq "#") -or ($HrefTag -eq "True")){
                            $HrefTag="True"
                            if ($FormattedString[$x] -eq "`""){
                                $HrefTag="False"
                                $FailTestDetail+=$LoopDetailInfo
                                $LoopDetailInfo=""
                            }
                            elseif ($FormattedString[$x] -ne "#"){
                                $LoopDetailInfo+=$FormattedString[$x]  
                            }
                        }
                    }
                }
                elseif ($TitleFound -eq "True"){
                    $SentenceStructure+=" "
                    for ($x=0;$x -lt $FormattedString.Length;$x++){
                        if ($FormattedString[$x] -eq "<"){
                            $FailTestArray+=$SentenceStructure
                            $SentenceStructure=''
                            $TitleFound="False"
                            $FailFound="False"
                            break
                        }
                        else{
                            $SentenceStructure+=$FormattedString[$x]
                        }
                    }
                    
                }
            }
        }

        # $FailTestArray ### Full Title of failed test
        # $FailTestDetail  ### HTML detail id
        
        $Global:FailTestArrayFinal=LinkDetail($FailTestArray,$FailTestDetail) ### Combine Title Number with HTML detail. ["1.1.1", "detail-d...", 1.1.2 ]
        Write-Output $Global:FailTestArrayFinal | Out-Null
    }

    Function IdentifyErrors{
        ### If it $Global:FailTestArrayFinal is empty, there are no errors
        if($Null -eq $Global:FailTestArrayFinal){
            # ### All Wrong output
            $Expression="$" + $Global:OutputBoxName + '.text+="There are no Incorrect Configuration `r`n"'
            
            Invoke-Expression $Expression
            $Global:AllCorrect=$True
            Write-Output $Global:AllCorrect | Out-Null

            $Global:NoErrors=$True
            Write-Output $Global:NoErrors | Out-null
        }
        else{
            # ### All Wrong output
            $Global:AllCorrect=$False
            $Expression="$" + $Global:OutputBoxName + '.text+="All Incorrect Configuration `r`n"'
            Invoke-Expression $Expression
            ### Get the registry key name and value
            $Global:NoErrors=$False
            
            $FailedIndex=-1
            $FailedIterate="True"
            $FormattedString2=""
            
            ### Identify Which section has been selected to filter the output
            if ($Global:SectionArray.Contains(1)){
                $SectionSelected1=$True
                $OutputSection1=$True
            }
            else{
                $SectionSelected1=$False
                $OutputSection1=$False
            }

            if ($Global:SectionArray.Contains(2)){
                $SectionSelected2=$True
                $OutputSection2=$True
            }
            else{
                $SectionSelected2=$False
                $OutputSection2=$False
            }

            if ($Global:SectionArray.Contains(5)){
                $SectionSelected5=$True
                $OutputSection5=$True
            }
            else{
                $SectionSelected5=$False
                $OutputSection5=$False
            }

            if ($Global:SectionArray.Contains(9)){
                $SectionSelected9=$True
                $OutputSection9=$True
            }
            else{
                $SectionSelected9=$False
                $OutputSection9=$False
            }

            if ($Global:SectionArray.Contains(17)){
                $SectionSelected17=$True
                $OutputSection17=$True
            }
            else{
                $SectionSelected17=$False
                $OutputSection17=$False
            }

            if ($Global:SectionArray.Contains(18)){
                $SectionSelected18=$True
                $OutputSection18=$True
            }
            else{
                $SectionSelected18=$False
                $OutputSection18=$False
            }

            if ($Global:SectionArray.Contains(19)){
                $SectionSelected19=$True
                $OutputSection19=$True
            }
            else{
                $SectionSelected19=$False
                $OutputSection19=$False
            }

            
            for ($x=0;$x -lt $Global:HTMLResults.Length;$x++){
                #Each string of html
                $LoopString2=$Global:HTMLResults[$x]
                #Remove Spaces (This will take forever, never call the line below in the for loop as there are 100K+ lines)
                #### $FormattedString2=RemoveFrontSpaces($LoopString2)

                ###Detailed number iteration
                if ($FailedIterate -eq "True"){
                    $FailedIndex+=2

                    ### Title
                    if($null -ne $Global:FailTestArrayFinal){
                        $Title=[String]$Global:FailTestArrayFinal[$FailedIndex-1]
                        $TitleNum=$Title.split(" ")
                        $TitleNum=[String]$TitleNum[0]
                        # $Global:SectionArray.Contains(2)
                        $LoopSplit=$TitleNum.split(".")
                        $TempArrayRS2=@()
                        $Section5Found=$False
                        for ($i=0; $i -lt $LoopSplit.length-1;$i++){
                            if ($i -eq "5"){
                                $Section5Found=$True
                            }
                            $TempArrayRS2+=$LoopSplit[$i]
                        }
                        if(-Not ($Section5Found)){
                            $TitleNum=$TempArrayRS2 -join "."
                        }
                        else{
                            $TitleNum="5"
                        }
                        # Write-Host $TitleNum
                        if ($TitleNum -eq "18.9.47"){
                            $TitleNum="18.9.47.14"
                        }

                        ### Section
                        $TempSection=$Title.split(".")
                        $SelectedSection=$TempSection[0]

                        if(($SectionSelected1 -eq $True) -and ($SelectedSection -eq "1")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 1 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression

                            $SectionSelected1=$False
                        }
                        if(($SectionSelected2 -eq $True) -and ($SelectedSection -eq "2")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 2 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected2=$False
                        }
                        if(($SectionSelected5 -eq $True) -and ($SelectedSection -eq "5")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 5 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected5=$False
                        }
                        if(($SectionSelected9 -eq $True) -and ($SelectedSection -eq "9")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 9 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected9=$False
                        }
                        if(($SectionSelected17 -eq $True) -and ($SelectedSection -eq "17")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 17 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected17=$False
                        }
                        if(($SectionSelected18 -eq $True) -and ($SelectedSection -eq "18")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 18 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected18=$False
                        }
                        if(($SectionSelected19 -eq $True) -and ($SelectedSection -eq "19")){
                            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Section 19 Incorrect Configurations `r`n"'
                            Invoke-Expression $Expression
                            $SectionSelected19=$False
                        }
                        if ((($OutputSection1 -eq $True) -and ($SelectedSection -eq "1")) -or (($OutputSection2 -eq $True) -and ($SelectedSection -eq "2")) -or 
                        (($OutputSection5 -eq $True) -and ($SelectedSection -eq "5")) -or (($OutputSection9 -eq $True) -and ($SelectedSection -eq "9")) -or
                        (($OutputSection17 -eq $True) -and ($SelectedSection -eq "17")) -or (($OutputSection18 -eq $True) -and ($SelectedSection -eq "18")) -or
                        (($OutputSection19 -eq $True) -and ($SelectedSection -eq "19"))){
                            foreach ($itemloop in $Global:SpecificSection){
                                if ($TitleNum -eq $itemloop){
                                    if (-Not ($Global:HiglightPg4.contains($itemloop))){
                                        $Global:HiglightPg4+=$itemloop
                                    }
                                    $Expression="$" + $Global:OutputBoxName + '.text+="$Title `r`n"'
                                    Invoke-Expression $Expression
                                    break
                                }
                            }
                        }

                        #Detail number
                        $SearchedLine=$Global:FailTestArrayFinal[$FailedIndex]
                        
                        ## e.g. <div id="detail-d1e60111" class="check">
                        $DetailLine= '<div id="'+ $SearchedLine +'" class="check">'

                        $FailedIterate="False"
                    }
                    
                }

                if ($LoopString2 -match $DetailLine){
                    $RKNameAndValue="True" ### Shows that the program needs to obtain the registry key and value next.
                }

                ### Contains the RK name and value
                ###$StringToMatch="<td>Ensure "
                if (($RKNameAndValue -eq "True") -and ($LoopString2 -match "<td>Ensure ")){
                    $RKNameAndValue="False"
                    $FormattedString2=RemoveFrontSpaces($LoopString2)

                    $SentenceStructure2=""
                    $SentenceStructure2+=$FormattedString2
                    if ($LoopString2 -notmatch "'</td>"){
                        $AdditionalInfo=$Global:HTMLResults[$x+1]
                        $SentenceStructure2+=RemoveFrontSpaces($AdditionalInfo)
                    }

                    ###<td>Ensure 'PreventDeviceMetadataFromNetwork' is 'Windows: Registry Value' to '1'</td>
                    $SentenceSplit=$SentenceStructure2 -split "'"
                    
                    $RKName   = $SentenceSplit[1]
                    $RKAction = $SentenceSplit[3]
                    $RKValue  = $SentenceSplit[5]

                    ### 19.7.8.5 is the only test that has "" set on the value.
                    if ($RKName -eq "DisableSpotlightCollectionOnDesktop"){
                        $RKValue=1
                    }

                    ### Some tests do not have an action. Move value from $RKAction to RKValue
                    if($null -eq $RKValue){
                        $RKAction = $SentenceSplit[5]
                        $RKValue  = $SentenceSplit[3]
                    }
                    
                    ###Creating an object
                    $Object=[PSCustomObject]@{
                        Title = $Title
                        RKName   = $RKName
                        RKAction = $RKAction
                        RKValue  = $RKValue
                    }
                    ### Adding the objcet into the array
                    $Global:DetailedArray+=$Object

                    ### Select next Detail id 
                    $FailedIterate="True"
                }

            }
        }

        
    }
    
    Function RemediateComputer{
        function FilterRegKey($InputValue){
            ### Section number
            $SelectedSection=$InputValue[0] ### Selected section to search
            $InputValueCount=$InputValue[1].Length ### Array of Objects 
            $FilteredRegKeyArray=""
            $FilteredRegKeyArray=@()
            ### $InputValue[1][1].Title -split " "
            for ($i=0;$i -lt $InputValueCount;$i++){
                ### Identify section number: e.g. 1,2,5,17
                $splitSpace=$InputValue[1][$i].Title -split " " ### 17.1.1 (L1) Ensure...
                $SectionFullNumber= $splitSpace[0] ###17.1.1
                $SplitPeriod= $SectionFullNumber.split(".") 
                $SectionNumber=$SplitPeriod[0] # Section number: 17
    
                if ($SectionNumber -eq $SelectedSection){
    
                    if ($InputValue[1][$i].Title -match "</a>"){
                        $TEMP=$InputValue[1][$i].Title -split "</a>"
                        $InputValue[1][$i].Title=$TEMP[0]
                        # $temploop=$TEMP[0]
                        $TEMP=""
                    }
    
                    $FilteredRegKeyArray+=$InputValue[1][$i]
                    
                }
                
            }
    
            return $FilteredRegKeyArray
        }
    
        ####### Remediation Function
    
        #### Remediate Section 1
    
        function RemediateSection1($CorrectConfig1){
        
            $ConfigArray1=""
            $ConfigArray1=@()
            
            ### CIS Benchmark does not provide the registry path, hence the registry path will be manual.
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'"
                Type = "NetAccount"
                Keyword = "UNIQUEPW"
                Value = 24
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.2 (L1) Ensure 'Maximum password age' is set to '365 or fewer days, but not 0'"
                Type = "NetAccount"
                Keyword = "MAXPWAGE"
                Value = 30
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.3 (L1) Ensure 'Minimum password age' is set to '1 or more day(s)'"
                Type = "NetAccount"
                Keyword = "MINPWAGE"
                Value = 1
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.4 (L1) Ensure 'Minimum password length' is set to '14 or more character(s)'"
                Type = "NetAccount"
                Keyword = "MINPWLEN"
                Value = 14
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.5 Ensure 'Password must meet complexity requirements' is set to 'Enabled'"
                Type = "SecPolicy"
                Keyword = "PasswordComplexity"
                Value = 1
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.6 (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'"
                Type = "Registry"
                path = 'HKLM:\System\CurrentControlSet\Control\SAM'
                Keyword = 'RelaxMinimumPasswordLengthLimits'
                ValueType = 'Dword'
                Value = 1
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.1.7 (L1) Ensure 'Store passwords using reversible encryption' is set to 'Disabled'"
                Type = "SecPolicy"
                Keyword = "ClearTextPassword"
                Value = 0
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.2.1 (L1) Ensure 'Account lockout duration' is set to '15 or more minute(s)'"
                Type = "SecPolicy"
                Keyword = "ResetLockoutCount"
                Value = 15
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.2.2 (L1) Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0'"
                Type = "NetAccount"
                Keyword = "Lockoutthreshold"
                Value = 5
            }
            $ConfigArray1+=$Config1
        
            $Config1 = [PSCustomObject]@{
                Title = "1.2.3 (L1) Ensure 'Reset account lockout counter after' is set to '15 or more minute(s)'"
                Type = "SecPolicy"
                Keyword = "LockoutBadCount"
                Value = 10
            }
            $ConfigArray1+=$Config1
        
            for ($i=0;$i -lt $CorrectConfig1.Length;$i++){
        
                ### Registry key names of Section 1 that are wrong
                $LoopTitle=$CorrectConfig1[$i]
                $LoopTitle=$LoopTitle.Title -split " "
                $LoopTitle=$LoopTitle[0]
                ### Compare here
                foreach ($item in $Global:SpecificSection){
                    if($LoopTitle.contains($item)){
                        ### Move For Loop here
                        ### Compare LoopTitle with the available list
                        for($x=0;$x -lt $ConfigArray1.Length;$x++){
                            $ConfigLoop=$ConfigArray1[$x]
                            $ConfigLoop=$ConfigLoop.Title -split " "
                            $ConfigLoop=$ConfigLoop[0]
                            if ($LoopTitle -eq $ConfigLoop){
                                ### Get type of remediation needed
                                $Section1Keyword=$ConfigArray1[$x].Keyword
                                $Section1Value=$ConfigArray1[$x].Value
                                $Section1Type=$ConfigArray1[$x].Type
                                if ($Section1Type -eq "Registry"){
                                    $Path=$ConfigArray1[$x].Path
                                    $Value=$ConfigArray1[$x].Value
                                    $ValueType=$ConfigArray1[$x].ValueType
                                }
                                if ($Section1Type -eq "NetAccount"){
                                    $Section1Keyword=$ConfigArray1[$x].Keyword + ':'
                                }
                                break
                            }
                            
                        }
                        if ($Section1Type -eq "NetAccount"){
                            $Combined="$Section1Keyword$Section1Value"
                            net accounts /$Combined | Out-Null
                        }
                        elseif ($Section1Type -eq "SecPolicy"){
    
                            secedit /export /cfg c:\secpol.cfg | Out-Null
    
                            (Get-Content C:\secpol.cfg).replace($Section1Keyword, "$Section1Keyword = $Section1Value") | Out-File C:\secpol.cfg | Out-Null
    
                            secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY | Out-Null
    
                            Remove-Item -force c:\secpol.cfg -confirm:$false | Out-Null
                        }
                        elseif($Section1Type -eq "Registry"){
                            if(-Not (Test-Path -path $Path)){
                                New-Item -Path $path -Force | Out-Null
                                
                            }
                            New-ItemProperty -Path $Path -Name $Section1Keyword -Value $Value -PropertyType $ValueType -Force | Out-Null
                        }
                        break
                    }
                    
                }
                    
            }
                
                
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 1 has completed `r`n"'
            Invoke-Expression $Expression
        }
    
        #### Remediate Section 2
        function RemediateSection2($CorrectConfig2){
    
            $ConfigArray2=""
            $ConfigArray2=@()
            ### CIS Benchmark does not provide the registry path, hence the registry path will be manual.
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NoConnectedUser' 
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord' #reg_dword
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'LimitBlankPasswordUse'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'SCENoApplyLegacyAuditPolicy'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'CrashOnAuditFail'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'AllocateDASD'
                Path = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
                Reg  = 'String'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'RequireSignOrSeal'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'SealSecureChannel'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'SignSecureChannel'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'DisablePasswordChange'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'MaximumPasswordAge'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'RequireStrongKey'
                Path = 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'DisableCAD'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
            
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'DontDisplayLastUserName'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'InactivityTimeoutSecs'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'LegalNoticeText'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'String' #sz
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'LegalNoticeCaption'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'String'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'passwordexpirywarning'
                Path = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ScRemoveOption'
                Path = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
                Reg  = 'String'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = "2.3.8.1 (L1) Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'"
                Name = 'RequireSecuritySignature'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = "2.3.8.2 (L1) Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'"
                Name = 'EnableSecuritySignature'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EnablePlainTextPassword'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'AutoDisconnect'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = "2.3.9.2 (L1) Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled'"
                Name = 'RequireSecuritySignature'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = "2.3.9.3 (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"
                Name = 'EnableSecuritySignature'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'enableforcedlogoff'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'SMBServerNameHardeningLevel'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'RestrictAnonymousSAM'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'RestrictAnonymous'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'DisableDomainCreds'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EveryoneIncludesAnonymous'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NullSessionPipes'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'MultiString'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'Machine' 
                Path = 'HKLM:\System\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedExactPaths'
                Reg  = 'MultiString'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'RestrictNullSessAccess'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'restrictremotesam'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
                Reg  = 'String'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NullSessionShares'
                Path = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters'
                Reg  = 'MultiString'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ForceGuest'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'UseMachineId'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'AllowNullSessionFallback'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'AllowOnlineID'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa\pku2u'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'SupportedEncryptionTypes'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NoLMHash'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'LmCompatibilityLevel'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'LDAPClientIntegrity'
                Path = 'HKLM:\System\CurrentControlSet\Services\LDAP'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NTLMMinClientSec'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
            
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'NTLMMinServerSec'
                Path = 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ObCaseInsensitive'
                Path = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Kernel'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ProtectionMode'
                Path = 'HKLM:\System\CurrentControlSet\Control\Session Manager'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'FilterAdministratorToken'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ConsentPromptBehaviorAdmin'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'ConsentPromptBehaviorUser'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EnableInstallerDetection'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EnableSecureUIAPaths'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EnableLUA'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'PromptOnSecureDesktop'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            $Config2 = [PSCustomObject]@{
                Title = ""
                Name = 'EnableVirtualization'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord'
            }
            $ConfigArray2+=$Config2
    
            ###Code
    
            ### Find the Registry Path (If applicable)
            for ($i=0;$i -lt $CorrectConfig2.Length;$i++){
                Write-Host $CorrectConfig2[$i]
                $Path2=""
                ### Registry key names of Section 2 that are wrong
                $RKNameLoop=$CorrectConfig2[$i]
    
                $LoopTitle=$CorrectConfig2[$i]
                $LoopTitle=$LoopTitle.Title -split " "
                $LoopTitle=$LoopTitle[0]  ### 2.3.10.10
    
                $LoopSplit=$LoopTitle.split(".")
                $TempArrayRS2=@()
                for ($x=0; $x -lt $LoopSplit.length-1;$x++){
                    $TempArrayRS2+=$LoopSplit[$x]
                }
                $LoopTitle=$TempArrayRS2 -join "."
    
                ### Compare here
                foreach ($item in $Global:SpecificSection){
                    ### $item = 2.3.1
    
                    if($LoopTitle -eq $item){
                            ### Compare RKNameLoop with the available list
                        for($x=0;$x -lt $ConfigArray2.Length;$x++){
                            
                            $ConfigLoop=$ConfigArray2[$x]
                            if ($RKNameLoop.RKName -eq $ConfigLoop.Name){
                                # ="True"
                                $Path2=$ConfigLoop.Path
                                $LoopType=$ConfigLoop.Reg
                                break
                            }
                            else{
                                # ="False"
                                $Path2="No Path"
                            }
                        }
                        # ###$CorrectConfig2[$i] | Add-Member -Name "Path" -MemberType "NoteProperty" -value $Path2
                        # $CorrectConfig2[$i].Title
                        ### Error on CIS part
                        if ($CorrectConfig2[$i].RKName -eq "setrustedcredmanaccessnameright"){
                            $CorrectConfig2[$i].RKName="SeTrustedCredManAccessPrivilege"
                        }
    
                        if ($CorrectConfig2[$i].RKName -eq "Deny access to this computer from the network"){
                            $CorrectConfig2[$i].RKName="SeDenyNetworkLogonRight"
                        }
    
                        if ($CorrectConfig2[$i].RKName -eq "SE_DENY_SERVICE_LOGON_NAME"){
                            $CorrectConfig2[$i].RKName="SeDenyServiceLogonRight"
                        }
                        ### Prefered value to use instead
                        if ($CorrectConfig2[$i].RKValue -eq "^(1|2|3)$"){
                            $CorrectConfig2[$i].RKValue= "1"
                        }
    
                        if ($CorrectConfig2[$i].RKValue -eq ".+"){
                            $CorrectConfig2[$i].RKValue= "Description of warning: Unauthorised use of the device is strictly prohibited"
                        }
    
                        if ($CorrectConfig2[$i].RKValue -eq "[a-zA-Z]"){
                            $CorrectConfig2[$i].RKValue= "MP Project Virtual Machine"
                        }
    
                        if (($CorrectConfig2[$i].RKName -eq "RequireSecuritySignature") -or ($CorrectConfig2[$i].RKName -eq "EnableSecuritySignature")){
                            for($y=0;$y -lt $ConfigArray2.count;$y++){
                                if($CorrectConfig2[$i].Title -eq $ConfigArray2[$y].Title){
                                    $Path2=$ConfigArray2[$y].Path
                                    break
                                }
                                
                            }
                            
                        }
                        ####Debug
                        # Write-Output "                     "
                        # $CorrectConfig2[$i].Title
    
                        #### For section 2, if a registry key does not have a path, it has to be configured differently compared to a registry key with a path.
                        if ($Path2 -eq "No Path"){
                            
                            # -Usernames "Administrators" -SecuritySetting "senetworklogonright" -SaveFile "C:\Config22.cfg"
                            $UsernameUnFormatted=$CorrectConfig2[$i].RKValue ### Value
                            $Usernames=$UsernameUnFormatted -split ", "
                            $SecuritySetting=$CorrectConfig2[$i].RKName ### RK name
                            $SaveFile = "C:\Config2.cfg"
                            $SettingExists="False"

                            ### Administrator name will change to Marcus
                            if ($SecuritySetting -eq "^S\-1\-5\-21\-\d+\-\d+\-\d+\-500$"){
                                $SecuritySetting="NewAdministratorName"
                                try{
                                    Rename-LocalUser -Name "Administrator" -NewName "Marcus"
                                }
                                catch{}
                                $Usernames="Marcus"
                            }
                            ### Guest name will change to friend
                            if ($SecuritySetting -eq "Guest"){
                                $SecuritySetting="NewGuestName"
                                try{
                                    Rename-LocalUser -Name "Guest" -NewName "friend"
                                }
                                catch{}
                                $Usernames="friend"
                            }
                            
                            Write-Host $Usernames
                            Write-Host $SecuritySetting

                            ### Function that gets User SID 
                            function GetSID($USER){
                                $objUser = New-Object System.Security.Principal.NTAccount("$USER")
                                $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
                                $strSID.Value
                            }
    
                            ### Create an export of the db configuration as a .cfg file to store changes.
                            secedit /export /cfg $SaveFile | Out-Null
                            ### Reads the contents of the file
                            $reader = [System.IO.File]::OpenText($SaveFile)
    
                            while($null -ne ($Line = $reader.ReadLine())) {
                                ### If setting exists
                                if ($Line -like "*$SecuritySetting*"){
                                    # Write-Output "Line found in Local.sdb"
                                    $SettingExists="True"
                                    break
                                }
                            }
                            $reader.Close()
    
                            Remove-Item -force $SaveFile -confirm:$false
    
                            ### Setting found in local.sdb file
                            if ($SettingExists -eq "True"){
                                $ReplacementLine= $line.Remove($line.IndexOf("="))
                                $ReplacementLine+= "= "
                                
                                $SaveFile = "C:\Config2A.cfg"
                                secedit /export /cfg $SaveFile | Out-Null
                                ### For loop that gets all user/s
                                # Write-Host "security setting:" $SecuritySetting
                                # Write-Host "Usernames: " + $Usernames
                                foreach($user in $Usernames){
                                    ### Some values might be SID form, hence, it doesnt require to change to sid form.
                                    $user=$user.trim()
                                    if ($user -match "S-1-"){
                                        $ReplacementLine+= "*"+$user+ ","
                                    }
                                    else{
                                        # Write-Host $user
                                        $ReplacementLine+= "*$(GetSID -USER "$user"),"
                                    }
                                }
                                ### Remove excess ","
                                $ReplacementLine= $ReplacementLine.Remove($ReplacementLine.LastIndexOf(","))
                                ### Replacing old configuration with new configuration
                                (Get-Content $SaveFile).replace("$Line", "$ReplacementLine") | Out-File $SaveFile
                                # Write-Output "First method"
                                # $ReplacementLine
                                ### saving the new configurations into the main file
                                secedit /configure /db c:\windows\security\local.sdb /cfg $SaveFile | Out-Null     ###/areas SECURITYPOLICY
    
                                Remove-Item -force $SaveFile -confirm:$false
    
                            }
    
                            ### Setting not found in local.sdb file
                            else{
                                ### The idea of adding a new line in local.sdb
                                ### 1) Export a copy of local.sdb (Whatever that is permissable to obtain)
                                ### 2) Add all the contents to an array through a while loop
                                ### 3) Add the new configuration to the copy through a foreach loop
                                ### 4) replace the old configuration with the new configuration
                                $SaveFile = "C:\Temp.cfg"
                                $Config2B=""
                                $Config2B=@()
                                ### (1)
                                secedit /export /cfg $SaveFile | Out-Null
                                $reader = [System.IO.File]::OpenText($SaveFile)
                                ### (2)
                                while($null -ne ($line = $reader.ReadLine())) {
                                    $Config2B+=$line
                                }
                                $reader.Close()
    
                                ### Create First temp file
                                New-Item -Path "C:\Config2B.cfg" | Out-Null
                                ### add array to first temp file
                                $Config2B | Out-File "C:\Config2B.cfg"
                                ### AddedLine
    
                                function Get-SID($USER){
                                    $objUser = New-Object System.Security.Principal.NTAccount("$USER")
                                    $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
                                    $strSID.Value
                                }
                                $LineToAdd=$SecuritySetting+"= "
                                foreach($user in $Usernames){
                                    $user=$user.trim()
                                    if ($user -match "S-1-"){
                                        $LineToAdd+= "*"+$user+ ","
                                    }
                                    else{
                                        $LineToAdd += "*$(Get-SID -USER "$user"),"
                                    }
                                }
                                $LineToAdd = $LineToAdd.Remove($LineToAdd.LastIndexOf(","))
    
    
                                ### Second Array
                                $newArray=""
                                $newArray=@()
    
                                $TempConfigFile=Get-Content -Path "C:\Config2B.cfg" 
                                ### (3)
                                foreach ($item in $TempConfigFile){
                                    if ($item -eq "[Privilege Rights]"){
                                        $newArray+=$item
                                        $newArray+=$LineToAdd
                                        
                                    }
                                    else{
                                        $newArray+=$item
                                    }
    
                                }
                                ### Second Temp file
                                New-Item -Path "C:\Config2BA.cfg" | Out-Null
                                $newArray | Out-File "C:\Config2BA.cfg"
                                ### (4)
                                secedit /configure /db c:\windows\security\local.sdb /cfg "C:\Config2BA.cfg" | Out-Null
    
                                Remove-Item -Path "C:\Temp.cfg"
                                Remove-Item -Path "C:\Config2B.cfg" 
                                Remove-Item -Path "C:\Config2BA.cfg"
    
                            }
    
                        }
                        ##### Remediation through registry key path
                        else{
                            #The catch script only runs if there's a terminating error. If the try executes correctly, 
                            #then it skips over the catch. You can access the exception information in the catch block using the $_ variable.
                            $RKNameFound="True"
                            $PathRK=[String]$Path2
                            $Name=[String]$RKNameLoop.RKName
                            # $Description=$RKNameLoop.Title
                            $CorrectValue=[String]$RKNameLoop.RKValue
                            $RKType=$LoopType
    
                            ### Identify if registry key exists
                            try
                            {
                                # $RegValue=Get-ItemPropertyValue -Path "$PathRK" -Name $Name
                                if (Test-Path -Path $PathRK){
                                    Get-ItemPropertyValue -Path $PathRK -Name $Name | Out-Null
                                }
                                else{
                                    $RKNameFound="False"
                                }
                                
                            }
                            catch
                            {
                                ### Registry Key not found
                                $RKNameFound="False"
                                # #$_ is the output from try{}
                                #$ErrorMessage= $_ 
                                
                            }
                            finally{
                                ### Registry Key name found (Exists in computer). Wrong configuration.
                                If ($RKNameFound -eq "True"){
                                        ###Changing registry key to correct value
                                        Set-ItemProperty  -path "$PathRK" -name "$Name" -value "$CorrectValue" #-PropertyType $RKType
                                    }
                                ### Registry Key name not found (Does no exists in computer). Missing configuration.
                                else{
                                    ###Creating a new registry key
                                    #'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                                    ###Split the $PathRK and put it in an array
                                    $TestPath=$PathRK -split "\\"
                                    ###The amount of file location (Exlcluding "HKLM:")
                                    $PathCount=$TestPath.count
                                    ###Adds \ in HKLM: -> HKLM:\
                                    $TempPath=$TestPath[0] + "\" 
                                    ###Starts from 1 to skip HKLM:
                                    for($i=1;$i -lt $PathCount; $i++){
                                        $TempDir=$TestPath[$i]  ### Registry key path without HKLM
                                        $TempPath+=$TempDir
                                        ###Test if path exist. Outputs True if it does and False if it doesn't
                                        $DirFound=Test-Path -Path "$TempPath"
                                        if($DirFound -eq $False){
                                            # Write-Output "Path does not exist"
                                            $IfTempPathArray=$TempPath -split "\\"
                                            
                                            ##Removes the last dir
                                            $IfTempPath= $IfTempPathArray -ne $TempDir
    
                                            ##Previous loop path.
                                            $TempPathJoin= $IfTempPath -join "\\"
                                            
                                            ### Creating a Registry path
                                            New-Item -Path "$TempPathJoin" -Name "$TempDir" | Out-Null
                                        }
                                        $TempPath+="\"
                                    }
                                    
                                    ### Creating a registry name and assigning a value
                                    New-ItemProperty -Path "$PathRK" -Name "$Name" -Value "$CorrectValue" -PropertyType $RKType | Out-Null
    
                                    # $Global:TotalFail2+=1
                                    # $Global:FailList2+=$Description
                                    #$ErrorMessage.GetType().Name
                                }
                            }
                                
                        }
                        break
                    }
                }
                    
                
            }
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 2 has completed `r`n"'
            Invoke-Expression $Expression
            ##Need change 
            # return $CorrectConfig2
    
        }
    
        ####### Remediation Function
    
        #### Remediate Section 5
        function RemediateSection5($CorrectConfig5){
    
            $ConfigArray5=""
            $ConfigArray5=@()
            ### CIS Benchmark does not provide the registry path, hence the registry path will be manual.
            $Config5 = [PSCustomObject]@{
                Title = "5.3 (L1) Ensure 'Computer Browser (Browser)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start' 
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Browser'
                Reg  = 'DWord' #reg_dword
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.6 (L1) Ensure 'IIS Admin Service (IISADMIN)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.7 (L1) Ensure 'Infrared monitor service (irmon)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\irmon'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.8 (L1) Ensure 'Internet Connection Sharing (ICS) (SharedAccess)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.10 (L1) Ensure 'LxssManager (LxssManager)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LxssManager'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.11 (L1) Ensure 'Microsoft FTP Service (FTPSVC)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\FTPSVC'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.13 (L1) Ensure 'OpenSSH SSH Server (sshd)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\sshd'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.24 (L1) Ensure 'Remote Procedure Call (RPC) Locator (RpcLocator)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Rpclocator'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.26 (L1) Ensure 'Routing and Remote Access (RemoteAccess)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.28 (L1) Ensure 'Simple TCP/IP Services (simptcp)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\simptcp'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.30 (L1) Ensure 'Special Administration Console Helper (sacsvr)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\sacsvr'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.31 (L1) Ensure 'SSDP Discovery (SSDPSRV)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
            
            $Config5 = [PSCustomObject]@{
                Title = "5.32 (L1) Ensure 'UPnP Device Host (upnphost)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\upnphost'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.33 (L1) Ensure 'Web Management Service (WMSvc)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WMSvc'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.36 (L1) Ensure 'Windows Media Player Network Sharing Service (WMPNetworkSvc)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WMPNetworkSvc'
                Reg  = 'DWord' 
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.37 (L1) Ensure 'Windows Mobile Hotspot Service (icssvc)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\icssvc'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.41 (L1) Ensure 'World Wide Web Publishing Service (W3SVC)' is set to 'Disabled' or 'Not Installed'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.42 (L1) Ensure 'Xbox Accessory Management Service (XboxGipSvc)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\XboxGipSvc'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.43 (L1) Ensure 'Xbox Live Auth Manager (XblAuthManager)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\XblAuthManager'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.44 (L1) Ensure 'Xbox Live Game Save (XblGameSave)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\XblGameSave'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
            $Config5 = [PSCustomObject]@{
                Title = "5.45 (L1) Ensure 'Xbox Live Networking Service (XboxNetApiSvc)' is set to 'Disabled'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\XboxNetApiSvc'
                Reg  = 'DWord'
            }
            $ConfigArray5+=$Config5
    
    
        # code
        ### Find The registry path (If applicable)
        for ($i=0;$i -lt $CorrectConfig5.Length;$i++){
                
            $Path5=""
            ### Registry key names of Section 5 that are wrong
            $ObjectLoop=$CorrectConfig5[$i]
            $SplitTitle=$ObjectLoop.Title -split " "
            ### Compare here
    
            # ### 5.1.1
            $ObjectTitleNumber= $SplitTitle[0]
    
            ### Compare ObjectLoop with the available list
            for($g=0;$g -lt $ConfigArray5.Count;$g++){
                $ConfigLoop=$ConfigArray5[$g]
                $SplitTitle=$ConfigLoop.Title -split " "
                $LoopTitleNumber=$SplitTitle[0]
                $ConfigNames=""
                if ($ObjectTitleNumber -eq $LoopTitleNumber){
    
                    $Path5=$ConfigLoop.path
                    $ConfigNames=$ConfigLoop.Name
                    $LoopType5=$ConfigLoop.Reg
                    break
                }
                
            }
                
            # }
            ####Debug
            # Write-Output "                     "
            # $CorrectConfig18[$i].Title
            
            ##### Remediation through registry key path
            for($x=0;$x -lt $ConfigNames.Count;$x++){
                $RKNameFound="True"
                ###$Path18 is the path
                if ($ConfigNames.Count -eq 1){
                    $Name=$ConfigNames
                }
                else{
                    $Name=$ConfigNames[$x]
                }
            }
    
                $CorrectValue=$ObjectLoop.RKValue
                $RKType5=$LoopType5
                #### CIS Errors
                if ($Name -eq "Start"){
                    $RKType5="Dword"
                    $CorrectValue=4
                }
                
                
                
                ### Identify if registry key exists
                #The catch script only runs if there's a terminating error. If the try executes correctly, 
                #then it skips over the catch. You can access the exception information in the catch block using the $_ variable.
                try
                {
                    # $RegValue=Get-ItemPropertyValue -Path "$Path5" -Name $Name
                    ### Check if path exists
                    if (Test-Path -Path $Path5){
                        ### Check if item exists
                        Get-ItemPropertyValue -Path $Path5 -Name $Name | Out-Null
                    }
                    else{
                        $RKNameFound="False"
                    }
                    
                }
                catch
                {
                    ### Registry Key not found
                    $RKNameFound="False"
                    # #$_ is the output from try{}
                    #$ErrorMessage= $_ 
                    
                }
                finally{
                    ### Registry Key name found (Exists in computer). Wrong configuration.
                    ### Debug: if statement is temporary
                    if ($Path5 -ne ""){
                        if ($RKNameFound -eq "True"){
                            ###Changing registry key to correct value
                            Set-ItemProperty  -path "$Path5" -name "$Name" -value "$CorrectValue" 
                        }
                        ### Registry Key name not found (Does no exists in computer). Missing configuration.
                        else{
                            ###Creating a new registry key
                            #'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                            ###Split the $Path5 and put it in an array
                            $TestPath=$Path5 -split "\\"
                            ###The amount of file location (Exlcluding "HKLM:")
                            $PathCount=$TestPath.count
                            ###Adds \ in HKLM: -> HKLM:\
                            $TempPath=$TestPath[0] + "\" 
                            ###Starts from 1 to skip HKLM:
                            for($y=1;$y -lt $PathCount; $y++){
                                $TempDir=$TestPath[$y]  ### Registry key path without HKLM
                                $TempPath+=$TempDir
                                ###Test if path exist. Outputs True if it does and False if it doesn't
                                $DirFound=Test-Path -Path "$TempPath"
                                if($DirFound -eq $False){
                                    # Write-Output "Path does not exist"
                                    $IfTempPathArray=$TempPath -split "\\"
                                    
                                    ##Removes the last dir
                                    $IfTempPath= $IfTempPathArray -ne $TempDir
    
                                    ##Previous loop path.
                                    $TempPathJoin= $IfTempPath -join "\\"
                                    
                                    ### Creating a Registry path
                                    New-Item -Path "$TempPathJoin" -Name "$TempDir" | Out-Null
                                }
                                $TempPath+="\"
                            }
                            
                            ### Creating a registry name and assigning a value
                            if ($Name -eq "DllName"){
                                New-ItemProperty -Path $Path5 -Name "$Name" -Value "$CorrectValue" | Out-Null
                            }
                            else{
                                New-ItemProperty -Path $Path5 -Name "$Name" -Value "$CorrectValue" -PropertyType $RKType5 | Out-Null
                            }
                            
                        }
                    }
                    else{
                        # Write-Output "No Path"
                    }
                    
                }
            }
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 5 has completed `r`n"'
            Invoke-Expression $Expression
        }
    
        ####### Remediation Function
    
        #### Remediate Section 9
        function RemediateSection9($CorrectConfig9){
    
            $ConfigArray9=""
            $ConfigArray9=@()
            ### CIS Benchmark does not provide the registry path, hence the registry path will be manual.
            $Config9 = [PSCustomObject]@{
                Title = "9.1.1 (L1) Ensure 'Windows Firewall: Domain: Firewall state' is set to 'On (recommended)'"
                Name = 'EnableFirewall' 
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
                Reg  = 'DWord' #reg_dword
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.2 (L1) Ensure 'Windows Firewall: Domain: Inbound connections' is set to 'Block (default)'"
                Name = 'DefaultInboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.3 (L1) Ensure 'Windows Firewall: Domain: Outbound connections' is set to 'Allow (default)'"
                Name = 'DefaultOutboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.4 (L1) Ensure 'Windows Firewall: Domain: Settings: Display a notification' is set to 'No'"
                Name = 'DisableNotifications'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.5 (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"
                Name = 'LogFilePath'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging'
                Reg  = 'String'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.6 (L1) Ensure 'Windows Firewall: Domain: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
                Name = 'LogFileSize'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.7 (L1) Ensure 'Windows Firewall: Domain: Logging: Log dropped packets' is set to 'Yes'"
                Name = 'LogDroppedPackets'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.1.8 (L1) Ensure 'Windows Firewall: Domain: Logging: Log successful connections' is set to 'Yes'"
                Name = 'LogSuccessfulConnections'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
            
            $Config9 = [PSCustomObject]@{
                Title = "9.2.1 (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"
                Name = 'EnableFirewall' 
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile'
                Reg  = 'DWord' #reg_dword
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.2 (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"
                Name = 'DefaultInboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.3 (L1) Ensure 'Windows Firewall: Private: Outbound connections' is set to 'Allow (default)'"
                Name = 'DefaultOutboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.4 (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"
                Name = 'DisableNotifications'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.5 (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"
                Name = 'LogFilePath'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging'
                Reg  = 'String'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.6 (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
                Name = 'LogFileSize'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.7 (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"
                Name = 'LogDroppedPackets'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.2.8 (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"
                Name = 'LogSuccessfulConnections'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.1 (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"
                Name = 'EnableFirewall' 
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord' #reg_dword
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.2 (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"
                Name = 'DefaultInboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.3 (L1) Ensure 'Windows Firewall: Public: Outbound connections' is set to 'Allow (default)'"
                Name = 'DefaultOutboundAction'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.4 (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"
                Name = 'DisableNotifications'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.5 (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"
                Name = 'AllowLocalPolicyMerge'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.6 (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"
                Name = 'AllowLocalIPsecPolicyMerge'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.7 (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"
                Name = 'LogFilePath'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging'
                Reg  = 'String'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.8 (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
                Name = 'LogFileSize'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.9 (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"
                Name = 'LogDroppedPackets'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            $Config9 = [PSCustomObject]@{
                Title = "9.3.10 (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"
                Name = 'LogSuccessfulConnections'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging'
                Reg  = 'DWord'
            }
            $ConfigArray9+=$Config9
    
            # code
        ### Find The registry path (If applicable)
        for ($i=0;$i -lt $CorrectConfig9.Length;$i++){
                
                $Path9=""
                ### Registry key names of Section 9 that are wrong
                $ObjectLoop=$CorrectConfig9[$i]
                $SplitTitle=$ObjectLoop.Title -split " "
    
                $LoopTitle=$SplitTitle[0]
                ### Compare here
                foreach ($item in $Global:SpecificSection){
                    if($LoopTitle.contains($item)){
                            # ### 9.1.1
                        $ObjectTitleNumber= $SplitTitle[0]
    
                        ### Compare ObjectLoop with the available list
                        for($g=0;$g -lt $ConfigArray9.Count;$g++){
                            $ConfigLoop=$ConfigArray9[$g]
                            $SplitTitle=$ConfigLoop.Title -split " "
                            $LoopTitleNumber=$SplitTitle[0]
                            $ConfigNames=""
                            if ($ObjectTitleNumber -eq $LoopTitleNumber){
    
                                $Path9=$ConfigLoop.path
                                $ConfigNames=$ConfigLoop.Name
                                $LoopType9=$ConfigLoop.Reg
                                break
                            }
                            
                        }
                        
                        # }
                        ####Debug
                        # Write-Output "                     "
                        # $CorrectConfig9[$i].Title
                        
                        ##### Remediation through registry key path
                        for($x=0;$x -lt $ConfigNames.Count;$x++){
                            $RKNameFound="True"
                            ###$Path9 is the path
                            if ($ConfigNames.Count -eq 1){
                                $Name=$ConfigNames
                            }
                            else{
                                $Name=$ConfigNames[$x]
                            }
                        }
                        $CorrectValue=$ObjectLoop.RKValue
                        $RKType9=$LoopType9
                        #### CIS Errors
                        if ($Name -eq "EnableFirewall"){
                            $RKType9="Dword"
                            $CorrectValue=1
                        }
                        if ($Name -eq "DefaultInboundAction"){
                            $RKType9="Dword"
                            $CorrectValue=1
                        }
                        if ($Name -eq "DefaultOutboundAction"){
                            $RKType9="Dword"
                            $CorrectValue=0
                        }
                        if ($Name-eq "DisableNotifications"){
                            $RKType9="Dword"
                            $CorrectValue=1
                        }
                        if ($Title -eq "9.1.5 (L1) Ensure 'Windows Firewall: Domain: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\domainfw.log'"){
                            $RKType9="String"
                            $CorrectValue="%SystemRoot%\System32\logfiles\firewall\domainfw.log"
                        }
                        if ($Name -eq "LogFileSize"){
                            $RKType9="Dword"
                            $CorrectValue=16384
                        }
                        if ($Name -eq "LogDroppedPackets"){
                            $RKType9="Dword"
                            $CorrectValue=1
                        }
                        if ($Name -eq "LogSuccessfulConnections"){
                            $RKType9="Dword"
                            $CorrectValue=1
                        }
                        if ($Name -eq "AllowLocalPolicyMerge"){
                            $RKType9="Dword"
                            $CorrectValue=0
                        }
                        if ($Name -eq "AllowLocalIPsecPolicyMerge"){
                            $RKType9="Dword"
                            $CorrectValue=0
                        }
                        if ($Title -eq "9.2.5 (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"){
                            $RKType9="String"
                            $CorrectValue="%SystemRoot%\System32\logfiles\firewall\privatefw.log"
                        }
                        if ($Title -eq "9.3.7 (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"){
                            $RKType9="String"
                            $CorrectValue="%SystemRoot%\System32\logfiles\firewall\publicfw.log"
                        }
                        ### Identify if registry key exists
                        #The catch script only runs if there's a terminating error. If the try executes correctly, 
                        #then it skips over the catch. You can access the exception information in the catch block using the $_ variable.
                        try
                        {
                            # $RegValue=Get-ItemPropertyValue -Path "$Path9" -Name $Name
                            ### Check if path exists
                            if (Test-Path -Path $Path9){
                                ### Check if item exists
                                Get-ItemPropertyValue -Path $Path9 -Name $Name | Out-Null
                            }
                            else{
                                $RKNameFound="False"
                            }
                            
                        }
                        catch
                        {
                            ### Registry Key not found
                            $RKNameFound="False"
                            # #$_ is the output from try{}
                            #$ErrorMessage= $_ 
                            
                        }
                        finally{
                            ### Registry Key name found (Exists in computer). Wrong configuration.
                            ### Debug: if statement is temporary
                            if ($Path9 -ne ""){
                                if ($RKNameFound -eq "True"){
                                    ###Changing registry key to correct value
                                    Set-ItemProperty  -path "$Path9" -name "$Name" -value "$CorrectValue" 
                                }
                                ### Registry Key name not found (Does no exists in computer). Missing configuration.
                                else{
                                    ###Creating a new registry key
                                    #'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                                    ###Split the $Path9 and put it in an array
                                    $TestPath=$Path9 -split "\\"
                                    ###The amount of file location (Exlcluding "HKLM:")
                                    $PathCount=$TestPath.count
                                    ###Adds \ in HKLM: -> HKLM:\
                                    $TempPath=$TestPath[0] + "\" 
                                    ###Starts from 1 to skip HKLM:
                                    for($y=1;$y -lt $PathCount; $y++){
                                        $TempDir=$TestPath[$y]  ### Registry key path without HKLM
                                        $TempPath+=$TempDir
                                        ###Test if path exist. Outputs True if it does and False if it doesn't
                                        $DirFound=Test-Path -Path "$TempPath"
                                        if($DirFound -eq $False){
                                            # Write-Output "Path does not exist"
                                            $IfTempPathArray=$TempPath -split "\\"
                                            
                                            ##Removes the last dir
                                            $IfTempPath= $IfTempPathArray -ne $TempDir
    
                                            ##Previous loop path.
                                            $TempPathJoin= $IfTempPath -join "\\"
                                            
                                            ### Creating a Registry path
                                            New-Item -Path "$TempPathJoin" -Name "$TempDir" | Out-Null
                                        }
                                        $TempPath+="\"
                                    }
                                    
                                        ### Creating a registry name and assigning a value
                                        if ($Name -eq "DllName"){
                                            New-ItemProperty -Path $Path9 -Name "$Name" -Value "$CorrectValue" | Out-Null
                                        }
                                        else{
                                            New-ItemProperty -Path $Path9 -Name "$Name" -Value "$CorrectValue" -PropertyType $RKType9 | Out-Null
                                        }
                                    
                                    
                                }
                            }
                            else{
                                # Write-Output "No Path"
                            }
                            
                        }
                        break
                    }
                }
            }
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 9 has completed `r`n"'
            Invoke-Expression $Expression
        }    
    
        #### Remediate Section 17
        function RemediateSection17($CorrectConfig17){
    
            ### Create directory if it doesn't exists
            if (-Not (Test-Path -Path "C:\Windows\System32\GroupPolicy\Machine")){
                New-Item -ItemType "directory" -Path "C:\Windows\System32\GroupPolicy\Machine" | Out-Null
            }
            if (-Not (Test-Path -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft")){
                New-Item -ItemType "directory" -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft" | Out-Null
            }
            if (-Not (Test-Path -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT")){
                New-Item -ItemType "directory" -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT" | Out-Null
            }
            if (-Not (Test-Path -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit")){
    
                New-Item -ItemType "directory" -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit" | Out-Null
            }
    
            ### If audit.csv is missing in the directory
            if (-not (Test-Path -Path "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit\audit.csv" -PathType Leaf)){
                # Write-Output "CSV NOT FOUND, cREATING NEW ONE"
                ### Create a CSV file with colums headers
                $CSVFile= "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit\audit.csv"
                New-Item $CSVFile -ItemType File | Out-Null
                Add-Content -Path $CSVFile -Value '"Machine Name","Policy Target","Subcategory","Subcategory GUID","Inclusion Setting","Exclusion Setting","Setting Value"'
            }
    
            ### Manual Assignment Only Subcategory and Subcategory GUID needed
            $CredentialValidation = New-Object -TypeName PSObject
            $SetObject17_1_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Credential Validation";
            "Subcategory GUID"="{0cce923f-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $CredentialValidation | Add-Member $SetObject17_1_1 -TypeName "17_1_1"
    
            $ApplicationGroupManagement = New-Object -TypeName PSObject
            $SetObject17_2_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Application Group Management";
            "Subcategory GUID"="{0cce9239-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $ApplicationGroupManagement | Add-Member $SetObject17_2_1 -TypeName "17_2_1"
            
            $AuditSecurityGroupManagement = New-Object -TypeName PSObject
            $SetObject17_2_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Security Group Management";
            "Subcategory GUID"="{0cce9237-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditSecurityGroupManagement | Add-Member $SetObject17_2_2 -TypeName "17_2_2"
            
            $AuditUserAccountManagement = New-Object -TypeName PSObject
            $SetObject17_2_3 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit User Account Management";
            "Subcategory GUID"="{0cce9235-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditUserAccountManagement | Add-Member $SetObject17_2_3 -TypeName "17_2_3"
            
            $AuditPNPActivity = New-Object -TypeName PSObject
            $SetObject17_3_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit PNP Activity";
            "Subcategory GUID"="{0cce9248-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditPNPActivity | Add-Member $SetObject17_3_1 -TypeName "17_3_1"
            
            $AuditProcessCreation = New-Object -TypeName PSObject
            $SetObject17_3_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Process Creation";
            "Subcategory GUID"="{0cce922b-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditProcessCreation | Add-Member $SetObject17_3_2 -TypeName "17_3_2"
            
            $AuditAccountLockout = New-Object -TypeName PSObject
            $SetObject17_5_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Account Lockout";
            "Subcategory GUID"="{0cce9217-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Failure";"Exclusion Setting"="";"Setting Value"="2"}
            $AuditAccountLockout | Add-Member $SetObject17_5_1 -TypeName "17_5_1"
            
            $AuditGroupMembership = New-Object -TypeName PSObject
            $SetObject17_5_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Group Membership";
            "Subcategory GUID"="{0cce9249-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditGroupMembership | Add-Member $SetObject17_5_2 -TypeName "17_5_2"
            
            $AuditLogoff = New-Object -TypeName PSObject
            $SetObject17_5_3 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Logoff";
            "Subcategory GUID"="{0cce9216-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditLogoff | Add-Member $SetObject17_5_3 -TypeName "17_5_3"
            
            $AuditLogon = New-Object -TypeName PSObject
            $SetObject17_5_4 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Logon";
            "Subcategory GUID"="{0cce9215-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditLogon | Add-Member $SetObject17_5_4 -TypeName "17_5_4"
            
            $AuditOtherLogonLogoffEvents = New-Object -TypeName PSObject
            $SetObject17_5_5 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Other Logon/Logoff Events";
            "Subcategory GUID"="{0cce921c-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditOtherLogonLogoffEvents | Add-Member $SetObject17_5_5 -TypeName "17_5_5"
            
            $AuditSpecialLogon = New-Object -TypeName PSObject
            $SetObject17_5_6 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Special Logon";
            "Subcategory GUID"="{0cce921b-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditSpecialLogon | Add-Member $SetObject17_5_6 -TypeName "17_5_6"
            
            $AuditDetailedFileShare = New-Object -TypeName PSObject
            $SetObject17_6_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Detailed File Share";
            "Subcategory GUID"="{0cce9244-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Failure";"Exclusion Setting"="";"Setting Value"="2"}
            $AuditDetailedFileShare | Add-Member $SetObject17_6_1 -TypeName "17_6_1"
            
            $AuditFileShare = New-Object -TypeName PSObject
            $SetObject17_6_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit File Share";
            "Subcategory GUID"="{0cce9224-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditFileShare | Add-Member $SetObject17_6_2 -TypeName "17_6_2"
            
            $AuditOtherObjectAccessEvents = New-Object -TypeName PSObject
            $SetObject17_6_3 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Other Object Access Events";
            "Subcategory GUID"="{0cce9227-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditOtherObjectAccessEvents | Add-Member $SetObject17_6_3 -TypeName "17_6_3"
            
            $AuditRemovableStorage = New-Object -TypeName PSObject
            $SetObject17_6_4 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Removable Storage";
            "Subcategory GUID"="{0cce9245-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditRemovableStorage | Add-Member $SetObject17_6_4 -TypeName "17_6_4"
            
            $AuditAuditPolicyChange = New-Object -TypeName PSObject
            $SetObject17_7_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Audit Policy Change";
            "Subcategory GUID"="{0cce922f-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditAuditPolicyChange | Add-Member $SetObject17_7_1 -TypeName "17_7_1"
            
            $AuditAuthenticationPolicyChange = New-Object -TypeName PSObject
            $SetObject17_7_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Authentication Policy Change";
            "Subcategory GUID"="{0cce9230-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditAuthenticationPolicyChange | Add-Member $SetObject17_7_2 -TypeName "17_7_2"
            
            $AuditAuthorizationPolicyChange = New-Object -TypeName PSObject
            $SetObject17_7_3 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Authorization Policy Change";
            "Subcategory GUID"="{0cce9231-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditAuthorizationPolicyChange | Add-Member $SetObject17_7_3 -TypeName "17_7_3"
            
            $AuditMPSSVCRuleLevelPolicyChange = New-Object -TypeName PSObject
            $SetObject17_7_4 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit MPSSVC Rule-Level Policy Change";
            "Subcategory GUID"="{0cce9232-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditMPSSVCRuleLevelPolicyChange | Add-Member $SetObject17_7_4 -TypeName "17_7_4"
            
            $AuditOtherPolicyChangeEvents = New-Object -TypeName PSObject
            $SetObject17_7_5 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Other Policy Change Events";
            "Subcategory GUID"="{0cce9234-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Failure";"Exclusion Setting"="";"Setting Value"="2"}
            $AuditOtherPolicyChangeEvents | Add-Member $SetObject17_7_5 -TypeName "17_7_5"
            
            $AuditSensitivePrivilegeUse = New-Object -TypeName PSObject
            $SetObject17_8_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Sensitive Privilege Use";
            "Subcategory GUID"="{0cce9228-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditSensitivePrivilegeUse | Add-Member $SetObject17_8_1 -TypeName "17_8_1"
            
            $AuditIPsecDriver = New-Object -TypeName PSObject
            $SetObject17_9_1 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit IPsec Driver";
            "Subcategory GUID"="{0cce9213-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditIPsecDriver | Add-Member $SetObject17_9_1 -TypeName "17_9_1"
            
            $AuditOtherSystemEvents = New-Object -TypeName PSObject
            $SetObject17_9_2 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Other System Events";
            "Subcategory GUID"="{0cce9214-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditOtherSystemEvents | Add-Member $SetObject17_9_2 -TypeName "17_9_2"
            
            $AuditSecurityStateChange = New-Object -TypeName PSObject
            $SetObject17_9_3 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Security State Change";
            "Subcategory GUID"="{0cce9210-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditSecurityStateChange | Add-Member $SetObject17_9_3 -TypeName "17_9_3"
            
            $AuditSecuritySystemExtension = New-Object -TypeName PSObject
            $SetObject17_9_4 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit Security System Extension";
            "Subcategory GUID"="{0cce9211-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success";"Exclusion Setting"="";"Setting Value"="1"}
            $AuditSecuritySystemExtension | Add-Member $SetObject17_9_4 -TypeName "17_9_4"
            
            $AuditSystemIntegrity = New-Object -TypeName PSObject
            $SetObject17_9_5 = [ordered]@{"Machine Name"="";"Policy Target"="System";"Subcategory"="Audit System Integrity";
            "Subcategory GUID"="{0cce9212-69ae-11d9-bed3-505054503030}";"Inclusion Setting"="Success and Failure";"Exclusion Setting"="";"Setting Value"="3"}
            $AuditSystemIntegrity | Add-Member $SetObject17_9_5 -TypeName "17_9_5"
            
            ###Array of Objects
            $ConfigArray17=""
            $ConfigArray17=@($CredentialValidation,$ApplicationGroupManagement,
            $AuditSecurityGroupManagement,$AuditUserAccountManagement,
            $AuditPNPActivity,$AuditProcessCreation,$AuditAccountLockout,
            $AuditGroupMembership,$AuditLogoff,$AuditLogon,
            $AuditOtherLogonLogoffEvents,$AuditSpecialLogon,$AuditDetailedFileShare,
            $AuditFileShare,$AuditOtherObjectAccessEvents,$AuditRemovableStorage,
            $AuditAuditPolicyChange,$AuditAuthenticationPolicyChange,
            $AuditAuthorizationPolicyChange,$AuditMPSSVCRuleLevelPolicyChange,
            $AuditOtherPolicyChangeEvents,$AuditSensitivePrivilegeUse,
            $AuditIPsecDriver,$AuditOtherSystemEvents,$AuditSecurityStateChange,
            $AuditSecuritySystemExtension,$AuditSystemIntegrity)
            
            ######## IMPORTANT PATH= "C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit\audit.csv"
            # ###$ImportPath="C:\Users\zikir\Desktop\audit1.csv"
            # ####$CSVFile=import-csv $ImportPath
            ## Add to csv
    
    
            ##Replace $ConfigArray17.count with $CorrectConfig17 [Title, Registry Key name]
    
            $CSVPath="C:\Windows\System32\GroupPolicy\Machine\Microsoft\Windows NT\Audit\audit.csv"
            Copy-Item -Path $CSVPath -Destination "C:\audit.csv"
    
            $ImportPath="C:\audit.csv"
            $ImportCSV= import-csv $ImportPath
            if ($null -eq $ImportCSV){### CSV file is empty
                for ($x=0;$x -lt $CorrectConfig17.count;$x++){
    
                    $SubcategoryWrongConfig=$CorrectConfig17[$x].Title -split "'"
                    $RKSubcategory=$SubcategoryWrongConfig[1] ###Subcategory
                    $RKValue=$SubcategoryWrongConfig[3] ###value
                    
                    if ($RKValue -eq "Success"){
                        $SettingValue=1
                    }
                    elseif ($RKValue -eq "Failure"){
                        $SettingValue=2
                    }
                    elseif ($RKValue -eq "Success and Failure"){
                        $SettingValue=3
                    }
    
                    ### Identify Subcategory GUID
                    for($i=0;$i -lt $ConfigArray17.count;$i++){
                        if($RKSubcategory -eq $ConfigArray17[$i]."Subcategory"){
                            $SubcategoryGUID=$ConfigArray17[$i]."Subcategory GUID"
                            break
                        }
                    }
    
                    ### Creating new line in CSV
                    $NewLine = "{0},{1},{2},{3},{4},{5},{6}" -f "","System",$RKSubcategory,$SubcategoryGUID,$RKValue,"",$SettingValue
                    $NewLine | add-content -path $ImportPath
                }
            }
    
            else{ ### Configured Wrongly
                $ForLoopCount=0
                for ($x=0;$x -lt $CorrectConfig17.count;$x++){
                
                    ### Compare here
                    $LoopTitle=$CorrectConfig17[$x]
                    $LoopTitle=$LoopTitle.Title -split " "
                    $LoopTitle=$LoopTitle[0]
                    # Write-Host $LoopTitle
                    foreach ($item in $Global:SpecificSection){
                        # Write-Host $item
                        if($LoopTitle.contains($item)){
                            # Write-Host "Found"
                            ###Remove Item
                            if ($ForLoopCount -eq 0){
                                $ImportPath=$CSVPath
                                $fileName=$LoopTitle.replace(".","_")
                                $ExportPath="C:\audit$fileName.csv"
                            }
                            else{
                                $PrevNum=$fileName
                                $ImportPath="C:\audit$PrevNum.csv"
                                $fileName=$LoopTitle.replace(".","_")
                                $ExportPath="C:\audit$fileName.csv"
                                $LastNumber=$fileName ##Used later on
                            }
                    
                            $ImportCSV= import-csv $ImportPath
                    
                            ### CSV file is not empty
                            $SubcategoryWrongConfig=$CorrectConfig17[$x].Title -split "'"
                            
    
                            $RKSubcategory=$SubcategoryWrongConfig[1] ###Subcategory
                            $RKValue=$SubcategoryWrongConfig[3] ###value
                            
                            if ($RKValue -eq "Success"){
                                $SettingValue=1
                            }
                            elseif ($RKValue -eq "Failure"){
                                $SettingValue=2
                            }
                            elseif ($RKValue -eq "Success and Failure"){
                                $SettingValue=3
                            }
                            ### Identify Subcategory GUID
                            for($i=0;$i -lt $ConfigArray17.count;$i++){
                                if($SubcategoryWrongConfig -eq $ConfigArray17[$i]."Subcategory"){
                                    $SubcategoryGUID=$ConfigArray17[$i]."Subcategory GUID"
                                    break
                                }
                            }
                            ### Find wrong config and replace with correct config
                            $ImportCSV |
                            where-Object "Subcategory" -NotLike $RKSubcategory |
                            export-csv $ExportPath -NoTypeInformation
                                
                            ###Remove previous file
                            if ($ForLoopCount -gt 0){
                                Remove-Item -Path "C:\audit$PrevNum.csv"
                            }
                            ###Create new line in CSV
                            $NewLine = "{0},{1},{2},{3},{4},{5},{6}" -f "","System",$RKSubcategory,$SubcategoryGUID,$RKValue,"",$SettingValue
                            $NewLine | add-content -path $ExportPath
                            $ForLoopCount+=1
                            break
                        }
                    } 
                }
                ##Remove Original File
                Remove-Item -Path $CSVPath
                Remove-Item -Path "C:\audit.csv"
                ### change the file name to audit.csv
                Move-Item -Path "C:\audit$LastNumber.csv" -Destination $CSVPath
    
            }
            (Get-Content $CSVPath) | ForEach-Object {$_ -replace "`"", ""} | out-file $CSVPath -Force -Encoding ascii

            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 17 has completed `r`n"'
            Invoke-Expression $Expression
        }
    
        #####Section 18
    
        function RemediateSection18($CorrectConfig18){
    
            $ConfigArray18=""
            $ConfigArray18=@()
            ### CIS Benchmark does not provide the registry path, hence the registry path will be manual.
            $Config18 = [PSCustomObject]@{
                Title = "18.1.1.1 (L1) Ensure 'Prevent enabling lock screen camera' is set to 'Enabled'"
                Name = 'NoLockScreenCamera' 
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.1.1.2 (L1) Ensure 'Prevent enabling lock screen slide show' is set to 'Enabled'"
                Name = 'NoLockScreenSlideshow'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            
            $Config18 = [PSCustomObject]@{
                Title = "18.1.2.2 (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'"
                Name = 'AllowInputPersonalization'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.1 (L1) Ensure LAPS AdmPwd GPO Extension / CSE is installed"
                Name = 'DllName'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{D76B9641-3288-4f75-942D-087DE603E3EA}'
                Reg  = 'String'
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.2 (L1) Ensure 'Do not allow password expiration time longer than required by policy' is set to 'Enabled'"
                Name = 'PwdExpirationProtectionEnabled'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.3 (L1) Ensure 'Enable Local Admin Password Management' is set to 'Enabled'"
                Name = 'AdmPwdEnabled'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.4 (L1) Ensure 'Password Settings: Password Complexity' is set to 'Enabled: Large letters + small letters + numbers + special characters'"
                Name = 'PasswordComplexity'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.5 (L1) Ensure 'Password Settings: Password Length' is set to 'Enabled: 15 or more'"
                Name = 'PasswordLength'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.2.6 (L1) Ensure 'Password Settings: Password Age (Days)' is set to 'Enabled: 30 or fewer'"
                Name = 'PasswordAgeDays'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.1 (L1) Ensure 'Apply UAC restrictions to local accounts on network logons' is set to 'Enabled'"
                Name = 'LocalAccountTokenFilterPolicy'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.2 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)'"
                Name = 'Start'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.3 (L1) Ensure 'Configure SMB v1 server' is set to 'Disabled'"
                Name = 'SMB1'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.4 (L1) Ensure 'Enable Structured Exception Handling Overwrite Protection (SEHOP)' is set to 'Enabled'"
                Name = 'DisableExceptionChainValidation'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.5 (L1) Ensure 'Limits print driver installation to Administrators' is set to 'Enabled'"
                Name = 'RestrictDriverInstallationToAdministrators'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{ 
                Title = "18.3.6 (L1) Ensure 'NetBT NodeType configuration' is set to 'Enabled: P-node (recommended)'"
                Name = 'NodeType'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.3.7 (L1) Ensure 'WDigest Authentication' is set to 'Disabled'"
                Name = 'UseLogonCredential'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.1 (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon (not recommended)' is set to 'Disabled'"
                Name = 'AutoAdminLogon'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.2 (L1) Ensure 'MSS: (DisableIPSourceRouting IPv6) IP source routing protection level (protects against packet spoofing)' is set to 'Enabled: Highest protection, source routing is completely disabled'"
                Name = 'DisableIPSourceRouting'
                Path = 'HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.3 (L1) Ensure 'MSS: (DisableIPSourceRouting) IP source routing protection level (protects against packet spoofing)' is set to 'Enabled: Highest protection, source routing is completely disabled'"
                Name = 'DisableIPSourceRouting'
                Path = 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.5 (L1) Ensure 'MSS: (EnableICMPRedirect) Allow ICMP redirects to override OSPF generated routes' is set to 'Disabled'"
                Name = 'EnableICMPRedirect'
                Path = 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.7 (L1) Ensure 'MSS: (NoNameReleaseOnDemand) Allow the computer to ignore NetBIOS name release requests except from WINS servers' is set to 'Enabled'"
                Name = 'nonamereleaseondemand'
                Path = 'HKLM:\System\CurrentControlSet\Services\NetBT\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.9 (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recommended)' is set to 'Enabled'"
                Name = 'SafeDllSearchMode'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.10 (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires (0 recommended)' is set to 'Enabled: 5 or fewer seconds'"
                Name = 'ScreenSaverGracePeriod'
                Path = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.4.13 (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less'"
                Name = 'WarningLevel'
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.4.1 (L1) Ensure 'Configure DNS over HTTPS (DoH) name resolution' is set to 'Enabled: Allow DoH' or higher"
                Name = 'DoHPolicy'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.4.2 (L1) Ensure 'Turn off multicast name resolution' is set to 'Enabled'"
                Name = 'EnableMulticast'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.8.1 (L1) Ensure 'Enable insecure guest logons' is set to 'Disabled'"
                Name = 'AllowInsecureGuestAuth'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.11.2 (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"
                Name = 'NC_AllowNetBridge_NLA'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.11.3 (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"
                Name = 'NC_ShowSharedAccessUI'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.11.4 (L1) Ensure 'Require domain users to elevate when setting a network's location' is set to 'Enabled'"
                Name = 'NC_StdDomainUserSetLocation'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.14.1 (L1) Ensure 'Hardened UNC Paths' is set to 'Enabled, with `"Require Mutual Authentication`" and `"Require Integrity`" set for all NETLOGON and SYSVOL shares'"
                Name = '\\*\NETLOGON','\\*\SYSVOL' #  ###MaximumLogFileSize  SYSTEM\CurrentControlSet\Services\Netlogon\Parameters
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.21.1 (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet'"
                Name = 'fMinimizeConnections'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WcmSvc\GroupPolicy'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.21.2 (L1) Ensure 'Prohibit connection to non-domain networks when connected to domain authenticated network' is set to 'Enabled'"
                Name = 'fBlockNonDomain'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WcmSvc\GroupPolicy'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.5.23.2.1 (L1) Ensure 'Allow Windows to automatically connect to suggested open hotspots, to networks shared by contacts, and to hotspots offering paid services' is set to 'Disabled'"
                Name = 'AutoConnectAllowedOEM'
                Path = 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.6.1 (L1) Ensure 'Allow Print Spooler to accept client connections' is set to 'Disabled'"
                Name = 'RegisterSpoolerRemoteRpcEndPoint'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            ###Duplicate
            $Config18 = [PSCustomObject]@{
                Title = "18.6.2 (L1) Ensure 'Point and Print Restrictions: When installing drivers for a new connection' is set to 'Enabled: Show warning and elevation prompt'"
                Name = 'NoWarningNoElevationOnInstall'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.6.3 (L1) Ensure 'Point and Print Restrictions: When updating drivers for an existing connection' is set to 'Enabled: Show warning and elevation prompt'"
                Name = 'UpdatePromptSettings' ###NoWarningNoElevationOnInstall
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.3.1 (L1) Ensure 'Include command line in process creation events' is set to 'Enabled'"
                Name = 'ProcessCreationIncludeCmdLine_Enabled'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.4.1 (L1) Ensure 'Encryption Oracle Remediation' is set to 'Enabled: Force Updated Clients'"
                Name = 'AllowEncryptionOracle'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.4.2 (L1) Ensure 'Remote host allows delegation of non-exportable credentials' is set to 'Enabled'"
                Name = 'AllowProtectedCreds'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.7.2 (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled'"
                Name = 'PreventDeviceMetadataFromNetwork'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.14.1 (L1) Ensure 'Boot-Start Driver Initialization Policy' is set to 'Enabled: Good, unknown and bad but critical'"
                Name = 'DriverLoadPolicy'
                Path = 'HKLM:\System\CurrentControlSet\Policies\EarlyLaunch'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.21.2 (L1) Ensure 'Configure registry policy processing: Do not apply during periodic background processing' is set to 'Enabled: FALSE'"
                Name = 'NoBackgroundPolicy'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Group Policy\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.21.3 (L1) Ensure 'Configure registry policy processing: Process even if the Group Policy objects have not changed' is set to 'Enabled: TRUE'"
                Name = 'NoGPOListChanges'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Group Policy\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.21.4 (L1) Ensure 'Continue experiences on this device' is set to 'Disabled'"
                Name = 'EnableCdp'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.21.5 (L1) Ensure 'Turn off background refresh of Group Policy' is set to 'Disabled'"
                Name = 'DisableBkGndGroupPolicy'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.22.1.2 (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled'"
                Name = 'DisableWebPnPDownload'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.22.1.6 (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled'"
                Name = 'NoWebServices'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.1 (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled'"
                Name = 'BlockUserFromShowingAccountDetailsOnSignin'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.2 (L1) Ensure 'Do not display network selection UI' is set to 'Enabled'"
                Name = 'DontDisplayNetworkSelectionUI'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.3 (L1) Ensure 'Do not enumerate connected users on domain-joined computers' is set to 'Enabled'"
                Name = 'DontEnumerateConnectedUsers'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.4 (L1) Ensure 'Enumerate local users on domain-joined computers' is set to 'Disabled'"
                Name = 'EnumerateLocalUsers'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.5 (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled'"
                Name = 'DisableLockScreenAppNotifications'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.6 (L1) Ensure 'Turn off picture password sign-in' is set to 'Enabled'"
                Name = 'BlockDomainPicturePassword'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.28.7 (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled'"
                Name = 'AllowDomainPINLogon'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.34.6.1 (L1) Ensure 'Allow network connectivity during connected-standby (on battery)' is set to 'Disabled'"
                Name = 'DCSettingIndex'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.34.6.2 (L1) Ensure 'Allow network connectivity during connected-standby (plugged in)' is set to 'Disabled'"
                Name = 'ACSettingIndex'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.34.6.5 (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled'"
                Name = 'DCSettingIndex'
                Path = 'HKLM:\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.34.6.6 (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled'"
                Name = 'ACSettingIndex'
                Path = 'HKLM:\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.36.1 (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled'"
                Name = 'fAllowUnsolicited'
                Path = 'HKLM:\Software\policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.36.2 (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled'"
                Name = 'fAllowToGetHelp'
                Path = 'HKLM:\Software\policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.8.37.1 (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled'"
                Name = 'EnableAuthEpResolution'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Rpc'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            
            $Config18 = [PSCustomObject]@{
                Title = "18.8.37.2 (L1) Ensure 'Restrict Unauthenticated RPC clients' is set to 'Enabled: Authenticated'"
                Name = 'RestrictRemoteClients'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows NT\Rpc'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.4.2 (L1) Ensure 'Prevent non-admin users from installing packaged Windows apps' is set to 'Enabled'"
                Name = 'BlockNonAdminUserInstall'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Appx'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.5.1 (L1) Ensure 'Let Windows apps activate with voice while the system is locked' is set to 'Enabled: Force Deny'"
                Name = 'LetAppsActivateWithVoiceAboveLock'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.6.1 (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled'"
                Name = 'MSAOptional'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.8.1 (L1) Ensure 'Disallow Autoplay for non-volume devices' is set to 'Enabled'"
                Name = 'NoAutoplayfornonVolume'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.8.2 (L1) Ensure 'Set the default behavior for AutoRun' is set to 'Enabled: Do not execute any autorun commands'"
                Name = 'NoAutorun'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.8.3 (L1) Ensure 'Turn off Autoplay' is set to 'Enabled: All drives'"
                Name = 'NoDriveTypeAutoRun'
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.10.1.1 (L1) Ensure 'Configure enhanced anti-spoofing' is set to 'Enabled'"
                Name = 'EnhancedAntiSpoofing'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\FacialFeatures'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.14.1 (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled'"
                Name = 'DisableConsumerAccountStateContent'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.14.3 (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled'"
                Name = 'DisableWindowsConsumerFeatures'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            
            $Config18 = [PSCustomObject]@{
                Title = "18.9.15.1 (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always'"
                Name = 'RequirePinForPairing' ###AllowProjectionToPC
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Connect'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.16.1 (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled'"
                Name = 'DisablePasswordReveal'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\CredUI'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.16.2 (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled'"
                Name = 'EnumerateAdministrators'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\CredUI'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.16.3 (L1) Ensure 'Prevent the use of security questions for local accounts' is set to 'Enabled'"
                Name = 'NoLocalPasswordResetQuestions'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.1 (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"
                Name = 'AllowTelemetry'  #  DisableTailoredExperiencesWithDiagnosticData
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.3 (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"
                Name = 'DisableOneSettingsDownloads'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.4 (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"
                Name = 'DoNotShowFeedbackNotifications'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.5 (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"
                Name = 'EnableOneSettingsAuditing'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.6 (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"
                Name = 'LimitDiagnosticLogCollection'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.7 (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"
                Name = 'LimitDumpCollection'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.17.8 (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"
                Name = 'AllowBuildPreview'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\PreviewBuilds'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.18.1 (L1) Ensure 'Download Mode' is NOT set to 'Enabled: Internet'"
                Name = 'DODownloadMode'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.1.1 (L1) Ensure 'Application: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
                Name = 'Retention'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Application'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.1.2 (L1) Ensure 'Application: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
                Name = 'MaxSize'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Application'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.2.1 (L1) Ensure 'Security: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
                Name = 'Retention'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Security'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.2.2 (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'"
                Name = 'MaxSize'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Security'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.3.1 (L1) Ensure 'Setup: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
                Name = 'Retention'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Setup'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.3.2 (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
                Name = 'MaxSize'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\Setup'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.4.1 (L1) Ensure 'System: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
                Name = 'Retention'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\System'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.27.4.2 (L1) Ensure 'System: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
                Name = 'MaxSize'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\EventLog\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            
            $Config18 = [PSCustomObject]@{
                Title = "18.9.31.2 (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"
                Name = 'NoDataExecutionPrevention'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.31.3 (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"
                Name = 'NoHeapTerminationOnCorruption'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.31.4 (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"
                Name = 'PreXPSP2ShellProtocolBehavior'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.36.1 (L1) Ensure 'Prevent the computer from joining a homegroup' is set to 'Enabled'"
                Name = 'DisableHomeGroup'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\HomeGroup'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.46.1 (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"
                Name = 'DisableUserAuth'
                Path = 'HKLM:\Software\Policies\Microsoft\MicrosoftAccount'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.4.1 (L1) Ensure 'Configure local setting override for reporting to Microsoft MAPS' is set to 'Disabled'"
                Name = 'LocalSettingOverrideSpynetReporting'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.5.1.1 (L1) Ensure 'Configure Attack Surface Reduction rules' is set to 'Enabled'"
                Name = 'ExploitGuard_ASR_Rules'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.5.1.2 (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"
                Name = '26190899-1602-49e8-8b27-eb1d0a1ce869','3b576869-a4ec-4529-8536-b80a7769e899',
                '5beb7efe-fd9a-4556-801d-275e5ffc04cc','75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84',
                '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c','92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b',
                '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2','b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4',
                'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550','d3e037e1-3eb8-44c8-a917-57927947596d',
                'd4f940ab-401b-4efc-aadc-ad5f3c50688a','e6db77e5-3df2-4cf1-b95a-636979351e5b'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.5.3.1 (L1) Ensure 'Prevent users and apps from accessing dangerous websites' is set to 'Enabled: Block'"
                Name = 'EnableNetworkProtection'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.9.1 (L1) Ensure 'Scan all downloaded files and attachments' is set to 'Enabled'"
                Name = 'DisableIOAVProtection'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.9.2 (L1) Ensure 'Turn off real-time protection' is set to 'Disabled'"
                Name = 'DisableRealtimeMonitoring'  ##DisableIOAVProtection
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.9.3 (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"
                Name = 'DisableBehaviorMonitoring'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.9.4 (L1) Ensure 'Turn on script scanning' is set to 'Enabled'"
                Name = 'DisableScriptScanning'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.12.1 (L1) Ensure 'Scan removable drives' is set to 'Enabled'"
                Name = 'DisableRemovableDriveScanning'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Scan'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.12.2 (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"
                Name = 'DisableEmailScanning'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender\Scan'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.15 (L1) Ensure 'Configure detection for potentially unwanted applications' is set to 'Enabled: Block'"
                Name = 'PUAProtection'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.47.16 (L1) Ensure 'Turn off Microsoft Defender AntiVirus' is set to 'Disabled'"
                Name = 'DisableAntiSpyware'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows Defender'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.58.1 (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"
                Name = 'DisableFileSyncNGSC'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.2.2 (L1) Ensure 'Do not allow passwords to be saved' is set to 'Enabled'"
                Name = 'DisablePasswordSaving'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.3.3 (L1) Ensure 'Do not allow drive redirection' is set to 'Enabled'"
                Name = 'fDisableCdm'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.9.1 (L1) Ensure 'Always prompt for password upon connection' is set to 'Enabled'"
                Name = 'fPromptForPassword'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
            
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.9.2 (L1) Ensure 'Require secure RPC communication' is set to 'Enabled'"
                Name = 'fEncryptRPCTraffic'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.9.3 (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"
                Name = 'SecurityLayer'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.9.4 (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"
                Name = 'UserAuthentication'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.9.5 (L1) Ensure 'Set client connection encryption level' is set to 'Enabled: High Level'"
                Name = 'MinEncryptionLevel'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.65.3.11.1 (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"
                Name = 'DeleteTempDirsOnExit'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.66.1 (L1) Ensure 'Prevent downloading of enclosures' is set to 'Enabled'"
                Name = 'DisableEnclosureDownload'
                Path = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Feeds'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.67.3 (L1) Ensure 'Allow Cortana' is set to 'Disabled'"
                Name = 'AllowCortana'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.67.4 (L1) Ensure 'Allow Cortana above lock screen' is set to 'Disabled'"
                Name = 'AllowCortanaAboveLock'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.67.5 (L1) Ensure 'Allow indexing of encrypted files' is set to 'Disabled'"
                Name = 'AllowIndexingEncryptedStoresOrItems'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.67.6 (L1) Ensure 'Allow search and Cortana to use location' is set to 'Disabled'"
                Name = 'AllowSearchToUseLocation'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.75.2 (L1) Ensure 'Only display the private store within the Microsoft Store' is set to 'Enabled'"
                Name = 'RequirePrivateStoreOnly'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsStore'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.75.3 (L1) Ensure 'Turn off Automatic Download and Install of updates' is set to 'Disabled'"
                Name = 'AutoDownload'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsStore'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.75.4 (L1) Ensure 'Turn off the offer to update to the latest version of Windows' is set to 'Enabled'"
                Name = 'DisableOSUpgrade'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsStore'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.81.1 (L1) Ensure 'Allow widgets' is set to 'Disabled'"
                Name = 'AllowNewsAndInterests'
                Path = 'HKLM:\Software\Policies\Microsoft\Dsh'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.85.1.1 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass'"
                Name = 'ShellSmartScreenLevel','EnableSmartScreen'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\System'
                Reg  = 'String' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.85.2.1 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled'"
                Name = 'EnabledV9'
                Path = 'HKLM:\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.85.2.2 (L1) Ensure 'Prevent bypassing Windows Defender SmartScreen prompts for sites' is set to 'Enabled'"
                Name = 'PreventOverride' 
                Path = 'HKLM:\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.87.1 (L1) Ensure 'Enables or disables Windows Game Recording and Broadcasting' is set to 'Disabled'"
                Name = 'AllowGameDVR'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\GameDVR'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.89.2 (L1) Ensure 'Allow Windows Ink Workspace' is set to 'Enabled: On, but disallow access above lock' OR 'Disabled' but not 'Enabled: On'"
                Name = 'AllowWindowsInkWorkspace'
                Path = 'HKLM:\Software\Policies\Microsoft\WindowsInkWorkspace'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.90.1 (L1) Ensure 'Allow user control over installs' is set to 'Disabled'"
                Name = 'EnableUserControl'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Installer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.90.2 (L1) Ensure 'Always install with elevated privileges' is set to 'Disabled'"
                Name = 'AlwaysInstallElevated'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\Installer'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.91.1 (L1) Ensure 'Sign-in and lock last interactive user automatically after a restart' is set to 'Disabled'"
                Name = 'DisableAutomaticRestartSignOn'
                Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.100.1 (L1) Ensure 'Turn on PowerShell Script Block Logging' is set to 'Enabled'"
                Name = 'EnableScriptBlockLogging'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.100.2 (L1) Ensure 'Turn on PowerShell Transcription' is set to 'Disabled'"
                Name = 'EnableTranscripting'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.1.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
                Name = 'AllowBasic'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.1.2 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
                Name = 'AllowUnencryptedTraffic'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.1.3 (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"
                Name = 'AllowDigest'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.2.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
                Name = 'AllowBasic'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.2.3 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
                Name = 'AllowUnencryptedTraffic'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.102.2.4 (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"
                Name = 'DisableRunAs'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.104.1 (L1) Ensure 'Allow clipboard sharing with Windows Sandbox' is set to 'Disabled'"
                Name = 'AllowClipboardRedirection'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sandbox'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.104.2 (L1) Ensure 'Allow networking in Windows Sandbox' is set to 'Disabled'"
                Name = 'AllowNetworking'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sandbox'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.105.2.1 (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'"
                Name = 'DisallowExploitProtectionOverride'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.1.1 (L1) Ensure 'No auto-restart with logged on users for scheduled automatic updates installations' is set to 'Disabled'"
                Name = 'NoAutoRebootWithLoggedOnUsers'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.2.1 (L1) Ensure 'Configure Automatic Updates' is set to 'Enabled'"
                Name = 'NoAutoUpdate'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.2.2 (L1) Ensure 'Configure Automatic Updates: Scheduled install day' is set to '0 - Every day'"
                Name = 'ScheduledInstallDay'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.2.3 (L1) Ensure 'Remove access to `“Pause updates`” feature' is set to 'Enabled'"
                Name = 'SetDisablePauseUXAccess'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.4.1 (L1) Ensure 'Manage preview builds' is set to 'Disabled'"
                Name = 'ManagePreviewBuildsPolicyValue'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.4.2 (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"
                Name = 'DeferFeatureUpdates','DeferFeatureUpdatesPeriodInDays'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            $Config18 = [PSCustomObject]@{
                Title = "18.9.108.4.3 (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"
                Name = 'DeferQualityUpdates','DeferQualityUpdatesPeriodInDays'
                Path = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Reg  = 'DWord' 
            }
            $ConfigArray18+=$Config18
    
            ## Code
    
            ### Find The registry path (If applicable)
            for ($i=0;$i -lt $CorrectConfig18.Length;$i++){
                
                $Path18=""
                ### Registry key names of Section 18 that are wrong
                $ObjectLoop=$CorrectConfig18[$i]
                $SplitTitle=$ObjectLoop.Title -split " "
                # ### 18.1.1
                $ObjectTitleNumber= $SplitTitle[0]
    
                $LoopTitle=$CorrectConfig18[$i]
                $LoopTitle=$LoopTitle.Title -split " "
                $LoopTitle=$LoopTitle[0]  ### 19.2.1
                $LoopSplit=$LoopTitle.split(".")
                $TempArrayRS18=@()
                for ($x=0; $x -lt $LoopSplit.length-1;$x++){
                    $TempArrayRS18+=$LoopSplit[$x]
                }
                $LoopTitle=$TempArrayRS18 -join "."
    
                ### Compare here
                foreach ($item in $Global:SpecificSection){
                    if ($LoopTitle -eq "18.9.47"){
                        $LoopTitle="18.9.47.14"
                    }
                    if($LoopTitle -eq $item){
                        ### Compare ObjectLoop with the available list
                        for($g=0;$g -lt $ConfigArray18.Count;$g++){
                            $ConfigLoop=$ConfigArray18[$g]
                            $SplitTitle=$ConfigLoop.Title -split " "
    
                            
                            $LoopTitleNumber=$SplitTitle[0]
                            $ConfigNames=""
                            if ($ObjectTitleNumber -eq $LoopTitleNumber){
    
                                $Path18=$ConfigLoop.path
                                $ConfigNames=$ConfigLoop.Name
                                $LoopType18=$ConfigLoop.Reg
                                break
                            }
                            
                        }
                            
                        # }
                        ####Debug
                        # Write-Output "                     "
                        # $CorrectConfig18[$i].Title
                        
                        ##### Remediation through registry key path
                        
                        
                        ### Some tests have more than 1 check
    
                        for($x=0;$x -lt $ConfigNames.Count;$x++){
                            $RKNameFound="True"
                            ###$Path18 is the path
                            if ($ConfigNames.Count -eq 1){
                                $Name=$ConfigNames
                            }
                            else{
                                $Name=$ConfigNames[$x]
                            }
                            ####Debug
                            # Write-Output "Name"
                            # $Name
                            # $Path18
                            
                            $CorrectValue=$ObjectLoop.RKValue
                            $RKType18=$LoopType18
                            #### CIS Errors
                            if ($Name -eq "ProcessCreationIncludeCmdLine_Enabled"){
                                $CorrectValue=1
                            }
                            if ($Name -eq "DODownloadMode"){
                                $CorrectValue=1
                            }
                            if ($Name -eq "EnableSmartScreen"){
                                $RKType18="DWord"
                                $CorrectValue=1
                            }
                            if ($Name -eq "DeferFeatureUpdatesPeriodInDays"){
                                $CorrectValue=180
                            }
                            
                            if ($Name -eq "DeferQualityUpdatesPeriodInDays"){
                                $CorrectValue=0
                            }
    
                            if ($CorrectValue -eq "[Rr]equire([Mm]utual[Aa]uthentication|[Ii]ntegrity)=1.*[Rr]equire([Mm]utual[Aa]uthentication|[Ii]ntegrity)=1"){
                                $CorrectValue="RequireMutualAuthentication=1, RequireIntegrity=1"
                            }
                            
                            
                            
                            
                            ### Identify if registry key exists
                            #The catch script only runs if there's a terminating error. If the try executes correctly, 
                            #then it skips over the catch. You can access the exception information in the catch block using the $_ variable.
                            try
                            {
                                # $RegValue=Get-ItemPropertyValue -Path "$Path18" -Name $Name
                                ### Check if path exists
                                if (Test-Path -Path $Path18){
                                    ### Check if item exists
                                    Get-ItemPropertyValue -Path $Path18 -Name $Name | Out-Null
                                }
                                else{
                                    $RKNameFound="False"
                                }
                                
                            }
                            catch
                            {
                                ### Registry Key not found
                                $RKNameFound="False"
                                # #$_ is the output from try{}
                                #$ErrorMessage= $_ 
                                
                            }
                            finally{
                                ### Registry Key name found (Exists in computer). Wrong configuration.
                                ### Debug: if statement is temporary
                                if ($Path18 -ne ""){
                                    if ($RKNameFound -eq "True"){
                                        ###Changing registry key to correct value
                                        Set-ItemProperty  -path "$Path18" -name "$Name" -value "$CorrectValue" #-PropertyType $RKType18
                                    }
                                    ### Registry Key name not found (Does no exists in computer). Missing configuration.
                                    else{
                                        ###Creating a new registry key
                                        #'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
                                        ###Split the $Path18 and put it in an array
                                        $TestPath=$Path18 -split "\\"
                                        ###The amount of file location (Exlcluding "HKLM:")
                                        $PathCount=$TestPath.count
                                        ###Adds \ in HKLM: -> HKLM:\
                                        $TempPath=$TestPath[0] + "\" 
                                        ###Starts from 1 to skip HKLM:
                                        for($y=1;$y -lt $PathCount; $y++){
                                            $TempDir=$TestPath[$y]  ### Registry key path without HKLM
                                            $TempPath+=$TempDir
                                            ###Test if path exist. Outputs True if it does and False if it doesn't
                                            $DirFound=Test-Path -Path "$TempPath"
                                            if($DirFound -eq $False){
                                                # Write-Output "Path does not exist"
                                                $IfTempPathArray=$TempPath -split "\\"
                                                
                                                ##Removes the last dir
                                                $IfTempPath= $IfTempPathArray -ne $TempDir
    
                                                ##Previous loop path.
                                                $TempPathJoin= $IfTempPath -join "\\"
                                                
                                                ### Creating a Registry path
                                                New-Item -Path "$TempPathJoin" -Name "$TempDir" | Out-Null
                                            }
                                            $TempPath+="\"
                                        }
                                        
                                        ### Creating a registry name and assigning a value
                                        if ($Name -eq "DllName"){
                                            New-ItemProperty -Path $Path18 -Name "$Name" -Value "$CorrectValue" | Out-Null
                                        }
                                        else{
                                            New-ItemProperty -Path $Path18 -Name "$Name" -Value "$CorrectValue" -PropertyType $RKType18 | Out-Null
                                        }
                                    }
                                }
                                else{
                                    # Write-Output "No Path"
                                }
                                
                            }
                        }
                        break
                    }
                }
            }
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 18 has completed `r`n"'
            Invoke-Expression $Expression
        }
    
        function RemediateSection19($CorrectConfig19){
        
            $ConfigArray19=""
            $ConfigArray19=@()
        
            $Config19 = [PSCustomObject]@{
                Title= "19.1.3.1 (L1) Ensure 'Enable screen saver' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
                Name = 'ScreenSaveActive' 
                Value = '1'
                Type = "String"
            }
            $ConfigArray19+=$Config19
        
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.1.3.2 (L1) Ensure 'Password protect the screen saver' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
                Name = 'ScreenSaverIsSecure' 
                Value = '1'
                Type = "String"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.1.3.3 (L1) Ensure 'Screen saver timeout' is set to 'Enabled: 900 seconds or fewer, but not 0'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
                Name = 'ScreenSaveTimeOut' 
                Value = '900'
                Type = "String"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title= "19.5.1.1 (L1) Ensure 'Turn off toast notifications on the lock screen' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
                Name = 'NoToastApplicationNotificationOnLockScreen' 
                Value = '1'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title= "19.7.4.1 (L1) Ensure 'Do not preserve zone information in file attachments' is set to 'Disabled'"
                registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments'
                Name = 'SaveZoneInformation' 
                Value = '2'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.7.4.2 (L1) Ensure 'Notify antivirus programs when opening attachments' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments'
                Name = 'ScanWithAntiVirus' 
                Value = '3'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.7.8.1 (L1) Ensure 'Configure Windows spotlight on lock screen' is set to Disabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
                Name = 'ConfigureWindowsSpotlight' 
                Value = '2'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.7.8.2 (L1) Ensure 'Do not suggest third-party content in Windows spotlight' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
                Name = 'DisableThirdPartySuggestions' 
                Value = '1'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title="19.7.8.5 (L1) Ensure 'Turn off Spotlight collection on Desktop' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
                Name = 'DisableSpotlightCollectionOnDesktop' 
                Value = '1'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
    
            $Config19 = [PSCustomObject]@{
                Title="19.7.28.1 (L1) Ensure 'Prevent users from sharing files within their profile.' is set to 'Enabled'"
                registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Name = 'NoInplaceSharing' 
                Value = '1'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            $Config19 = [PSCustomObject]@{
                Title=  "19.7.43.1 (L1) Ensure 'Always install with elevated privileges' is set to 'Disabled'"
                registryPath = 'HKCU:\Software\Policies\Microsoft\Windows\Installer'
                Name = 'AlwaysInstallElevated' 
                Value = '0'
                Type = "Dword"
            }
            $ConfigArray19+=$Config19
        
            for ($i=0;$i -lt $CorrectConfig19.length;$i++){
                $Loop19Name=$CorrectConfig19[$i].RKName
    
                $LoopTitle=$CorrectConfig19[$i]
                $LoopTitle=$LoopTitle.Title -split " "
                $LoopTitle=$LoopTitle[0]  ### 19.2.1
    
                $LoopSplit=$LoopTitle.split(".")
                $TempArrayRS19=@()
                for ($x=0; $x -lt $LoopSplit.length-1;$x++){
                    $TempArrayRS19+=$LoopSplit[$x]
                }
                $LoopTitle=$TempArrayRS19 -join "."
                ### Compare here
                foreach ($item in $Global:SpecificSection){
                    if($LoopTitle -eq $item){
                        for($x=0;$x -lt $ConfigArray19.length;$x++){
                            $compareAgainstName=$ConfigArray19[$x].Name
                            if ($Loop19Name -eq $compareAgainstName){
                                # $Loop19Name
                                $WrongConfig=$False
                                try{
                                    $Name=Get-ItemPropertyValue -Path $Path -Name $compareAgainstName
                                    Get-ItemPropertyValue -Path $ConfigArray19[$x].registryPath -Name $ConfigArray19[$x].Name
                                }
                                catch{
                                    $WrongConfig=$True
                                    if (-NOT (Test-Path $ConfigArray19[$x].registryPath)) {
                                        New-Item -Path $ConfigArray19[$x].registryPath -Force | Out-Null
                                    }
                                    New-ItemProperty -Path $ConfigArray19[$x].registryPath -Name $ConfigArray19[$x].Name -Value $ConfigArray19[$x].Value -PropertyType $ConfigArray19[$x].Type -Force | Out-Null
                                }
            
                                if(-Not $WrongConfig){
                                    Set-ItemProperty -Path $ConfigArray19[$x].registryPath -Name $ConfigArray19[$x].Name -Value $ConfigArray19[$x].Value -Force | Out-Null
                                }
                                Write-Output "$Name" | Out-Null
                                break
                            }
                        }
                        break
                    }
                }
            }
            # try{
            #     New-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "900" -PropertyType "String" -Force | Out-Null
            # }
            # catch{
            #     $ScreenSaveTimeOut="Found"
            # }
            # Write-Output "$ScreenSaveTimeOut" | out-null
            $Expression="$" + $Global:OutputBoxName + '.text+="Remediation for Section 19 has completed `r`n"'
            Invoke-Expression $Expression
        }

        ################# Remediation #################
        #### New-Item "C:\Users\zikir\Desktop\test2.txt"
        #### Set-Content "C:\Users\zikir\Desktop\test2.txt" $CorrectConfig2

        #### Remediate Section 1

        
        if ($Global:SectionArray.Contains(1)){
            $CorrectConfig1=FilterRegKey("1",$Global:DetailedArray) ### Filter the overall array to only inlucde section 2 errors
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 1 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection1($CorrectConfig1)
        }
    
        ### Remediate Section 2 (Done)
        ### $CorrectConfig2 is an object that has Title, RKName, RKAction and RKValue
        if ($Global:SectionArray.Contains(2)){
            $CorrectConfig2=FilterRegKey("2",$Global:DetailedArray) ### Filter the overall array to only inlucde section 2 errors
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 2 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection2($CorrectConfig2)
        }
    
        ### Remediate Section 5 (Done)
        if ($Global:SectionArray.Contains(5)){
            $CorrectConfig5=FilterRegKey("5",$Global:DetailedArray) ### Filter the overall array to only inlucde section 5 errors
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 5 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection5($CorrectConfig5)
        }
    
        ### Remediate Section 9 (Done)
        if ($Global:SectionArray.Contains(9)){
            $CorrectConfig9=FilterRegKey("9",$Global:DetailedArray) ### Filter the overall array to only inlucde section 9 errors
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 9 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection9($CorrectConfig9)
        }
        
        ### Remediate Section 17 (Done)
        if ($Global:SectionArray.Contains(17)){
            $CorrectConfig17=FilterRegKey("17",$Global:DetailedArray) ### FilterRegKey(Selected Section, ArrayFailList) ### e.g. ["17.1.1 Audit Credential Authentication", ...]
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 17 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection17($CorrectConfig17) ### Remediate all section 17 errors.
        }
    
        ### Remediate Section 18 (Done)
        if ($Global:SectionArray.Contains(18)){
            $CorrectConfig18=FilterRegKey("18",$Global:DetailedArray) ### FilterRegKey(Selected Section, ArrayFailList)
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 18 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection18($CorrectConfig18) ### Remediate all section 18 errors.
        }
    
        if ($Global:SectionArray.Contains(19)){
            $CorrectConfig19=FilterRegKey("19",$Global:DetailedArray) ### Filter the overall array to only inlucde section 2 errors
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Remediation for Section 19 has began `r`n"'
            Invoke-Expression $Expression
            RemediateSection19($CorrectConfig19)
        }
    
        ## Update Group Policy
        gpupdate.exe
        $Expression="$" + $Global:OutputBoxName + '.text+="`r`n `r`n Remediation has been completed. `r`n"'
        Invoke-Expression $Expression
    }
    
        
    ### Calls the Read file function
    ### read file
    # $Global:FailTestArrayFinal
    if($Global:ReadFile){
        ReadFile
        IdentifyErrors
    }
       
    ### If remediationg is selected
    # $Global:DetailedArray
    if ($Global:Remediate -and -Not ($Global:NoErrors)){
        # Write-Host $Global:SectionArray + "Section array"
        # Write-Host $Global:SpecificSection + "Specific section"
        RemediateComputer
    }
    else{
        if ($Null -ne $Global:FailTestArrayFinal){
            $Expression="$" + $Global:OutputBoxName + '.text+="`r`n Failure Identification has been completed. `r`n"'
            Invoke-Expression $Expression
        }

    }

}

### Check Windows
Function RemediateWindows(){
    # $Global:RemediateGroupChartCountFail =0
    # $Global:RemediateGroupChartCountPass =0
    # $Global:RemediateFolderChartCountFail =0
    # $Global:RemediateFolderChartCountPass =0
    $ConfigFile = $global:TxtFile
    $ConfigKeys = @{}
    Get-Content $ConfigFile | ForEach-Object {
    $Keys = $_ -split "="
    $ConfigKeys += @{$Keys[0]=$Keys[1]}
    }
    $OutputBox10.text+="Now remediating Groups and Users configurations." + "`r`n" + "`r`n"
    foreach($line in Get-Content $global:TxtFile){
        if($line -match "drive="){
            $Global:DriveSelect= $line.split("=")
            $Global:DriveSelect= $Global:DriveSelect[1]
            break
        }
    }
    $countgroup=1
    foreach($line in Get-Content $global:TxtFile){
        $MemberCompConfig=""
        $MemberCompConfig=@()
        if($line -match "group[1234567890]="){
            $grouploop = '$ConfigKeys.group' + $countgroup
            $grouploop = Invoke-Expression $grouploop
            $VariableGroup=net localgroup $grouploop
            $DashCheck=$False
            for($i=0;$i -lt $VariableGroup.length;$i++){
                $LoopItem=[String]$VariableGroup[$i]
                if($i -eq 0){
                    $Alias=$LoopItem.split("     ")
                    $Alias=$Alias[-1]
                    # Write-Host $Alias
                }
                if ($LoopItem.Contains("The command completed successfully.")){
                    $DashCheck=$False
                }
                if($DashCheck){
                    ### Computer config
                    $MemberCompConfig+=$LoopItem
                }
                if($LoopItem.contains("---")){
                    $DashCheck=$True
                }
            }
            ### From config file
            $loopGroup = "$"+ "ConfigKeys.group" + $countgroup
            $loopGroup = Invoke-Expression $loopGroup 
            $MemberConfFile = "$"+ "ConfigKeys.member" + $countgroup
            $MemberConfFile = Invoke-Expression $MemberConfFile
            
            if ($MemberConfFile.contains(",")){
                $MemberConfFile=$MemberConfFile.split(",")
            }
            else{
                $MemberConfFile=@("$MemberConfFile")
            }
            ### compare length: If conf file > computer config -> Missing
            ### compare length: If Computer Config > Conf file -> Excess accounts = wrong
            $ConfFileLength=$MemberConfFile.length
            # $MemberConfFile
            $CompConfigLength=$MemberCompConfig.length
            # Write-Host $ConfFileLength + "Conf file"
            # Write-Host $CompConfigLength + "Computer"
            if($ConfFileLength -gt $CompConfigLength){
                ###Missing
                for($x=0;$x -lt $ConfFileLength;$x++){
                    $tempItem=$MemberConfFile[$x]
                    if(-Not($tempItem -like $MemberCompConfig)){
                        $OutputBox10.text+= $tempItem + " is not found in $Alias" + "`r`n"
                        #command to add member ($tempItem) to group ($Alias)
                        net localgroup $Alias $tempItem /add
                    }
                }
                $OutputBox10.text+= "$Alias is now remediated." + "`r`n"
                $Global:RemediateGroupChartCountFail +=1
            }
            elseif($CompConfigLength -gt $ConfFileLength){
                ###Wrong
                for($x=0;$x -lt $CompConfigLength;$x++){
                    $tempItem=$MemberCompConfig[$x]
                    if(-Not($tempItem -like $MemberConfFile)){ 
                        $OutputBox10.text+=$tempItem + " is an excess account in $Alias" + "`r`n"
                        #command to remove member ($tempItem) from group ($Alias)
                        net localgroup $Alias $tempItem /delete
                    }
                }
                $OutputBox10.text+= "$Alias is now remediated." + "`r`n"
                # $Global:RemediateGroupChartCountFail +=1
            }
            else{
                $ConfigCorrect=$True
                for($x=0;$x -lt $ConfFileLength;$x++){
                    $tempItem=$MemberConfFile[$x]
                    if($MemberCompConfig -like $tempItem){
                        ### correct
                    }
                    else{
                        $ConfigCorrect=$False
                        ###Missing
                        # Write-Host "lol" + $tempItem
                        # Write-Host "lol2" + $MemberCompConfig
                        if(-Not($tempItem -like $MemberCompConfig)){
                            $OutputBox10.text+= $tempItem + " is not found in $Alias" + "`r`n"
                            #command to add member ($tempItem) to group ($Alias)
                            net localgroup $Alias $tempItem /add
                        }
                    }
                }
                for($y=0;$y -lt $CompConfigLength;$y++){
                    $tempItem=$MemberCompConfig[$y]
                    if(-Not($MemberConfFile -contains $tempItem)){
                        $OutputBox10.text+=$tempItem + " is not suppose to be in $Alias" + "`r`n"
                        #command to remove member ($tempItem) from group ($Alias)
                        net localgroup $Alias $tempItem /delete
                    }
                }
                #Scoring with comparison (if/else)
                if (($Alias.contains($loopGroup)) -and ($ConfigCorrect)) {
                    $OutputBox10.text+="$Alias does not need remediation." + "`r`n"
                    # $Global:RemediateGroupChartCountPass += 1
                }
                else{
                    $OutputBox10.text+="$Alias has been remediated." + "`r`n"
                    # $Global:RemediateGroupChartCountFail += 1
                }
            }
            $countgroup++ 
            $OutputBox10.text+= " " + "`r`n"
        }
    }

    ### make sure got space in between outputs
    $OutputBox10.text+=" " + "`r`n"
    $OutputBox10.text+="Now remediating folder configurations." + "`r`n"

    function GetFolder ($folder) {
        $ExpressionGetFolder='(get-acl ' + $Global:DriveSelect + ':\' + $folder + ').access | Select-Object `
        @{Label="Identity";Expression={$_.IdentityReference}}, `
        @{Label="Right";Expression={$_.FileSystemRights}}'
        $Global:DriveStatus=$True
        Write-Output $Global:DriveStatus | Out-Null

        try{
            if (Test-Path -Path $Global:DriveSelect":\$folder"){
                Invoke-Expression $ExpressionGetFolder
                $Global:DriveStatus=$True
            }
            else{
                $Global:DriveStatus=$False
            }
        }
        catch{
            $Global:DriveStatus=$False
        }
    }
    $machinename=hostname 
    $countfolder=1
    try{
        if (Get-PSDrive $Global:DriveSelect){ 
            $OutputBox10.text+="Drive $Global:DriveSelect is mounted properly." + "`r`n"
            foreach($line in Get-Content $global:TxtFile){
                if($line -match "folder[1234567890]="){
                    $folderloop = '$folder= $ConfigKeys.folder' + $countfolder
                    $folderloop = Invoke-Expression $folderloop
                    $VariableFolder=GetFolder $folder
                    if ($Global:DriveStatus -eq $True){
                        for($i=0;$i -lt $VariableFolder.length;$i++){
                            $LoopItemFolder=[String]$VariableFolder[$i]
                            if($i -eq 0){
                                $Identity=$LoopItemFolder.split("\")
                                $Identity=$Identity[1]
                                $Identity=$Identity.split(";")
                                $Admin=$Identity[0]
                                $AdminRight=$Identity[1]
                                $AdminRight=$AdminRight.Split("=")
                                $AdminRight=$AdminRight[1]
                                $AdminRight=$AdminRight -replace '}',''
                            }
                            if ($i -eq 1){
                                $Identity=$LoopItemFolder.split("\")
                                $Identity=$Identity[1]
                                $Identity=$Identity.split(";")
                                $MemberIdentity=$Identity[0]
                                $Right=$Identity[1]
                                $Right=$Right.Split("=")
                                $Right=$Right[1]
                                $MemberRight=$Right -replace '}',''
                            }
                        }
                        #Scoring with comparison (if/else)
                        $loopAdmin = "$"+ "ConfigKeys.admin" + $countfolder
                        $loopAdmin = Invoke-Expression $loopAdmin 
                        $loopFolder = "$"+ "ConfigKeys.folder" + $countfolder
                        $loopFolder = Invoke-Expression $loopFolder
                        $loopRight = "$"+ "ConfigKeys.right" + $countfolder
                        $loopRight = Invoke-Expression $loopRight
                        $loopIdentity = "$"+ "ConfigKeys.identity" + $countfolder
                        $loopIdentity = Invoke-Expression $loopIdentity
                        # Write-Host "start"
                        # $Admin
                        # $ConfigKeys.folderadmin
                        # $AdminRight
                        # $loopAdmin
                        # Write-Host "End"
                    }
                    if($Global:DriveStatus -eq $False) {
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="$folder path is not configured properly."
                        #command to create folder ($folder) under the right path ($DriveSelect)
                        New-Item -Path "$DriveSelect`:\" -Name "$folder" -ItemType "directory"
                        #command to add member ($loopidentity) with rights ($loopRight)
                        $NewAcl = Get-Acl -Path "$DriveSelect`:\$folder"
                        #Set properties
                        $identity = "$machinename\$loopIdentity"
                        $fileSystemRights = "$loopRight"
                        $type ="Allow"                    #Create new rule
                        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
                        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
                        # Apply new rule
                        $NewAcl.SetAccessRule($fileSystemAccessRule)
                        Set-Acl -Path "$DriveSelect`:\$folder" -AclObject $NewAcl
                        $OutputBox10.text+="$folder is now remediated." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                    }
                    elseif (($Admin -inotlike $ConfigKeys.folderadmin) -and ($AdminRight -inotlike $loopAdmin)){
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="Admin name and permissions is not configured properly." + "`r`n"
                        $OutputBox10.text+="Requires manual remediation." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                        #can't remediate
                    }
                    elseif ($Admin -inotlike $ConfigKeys.folderadmin){
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="Admin name is not configured properly." + "`r`n"
                        $OutputBox10.text+="Requires manual remediation." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                        #can't remediate
                    }
                    elseif ($AdminRight -inotlike $loopAdmin){
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="Admin permissions is not configured properly." + "`r`n"
                        $OutputBox10.text+="Requires manual remediation." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                        #can't remediate
                    }
                    elseif (($MemberIdentity -inotlike $loopIdentity) -and  ($MemberRight -inotlike $loopRight)){
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="$MemberIdentity name and permissions is not configured properly."
                        #command to remove member ($MemberIdentity) from folder ($folder)
                        $RemAcl = Get-Acl -Path "$DriveSelect`:\$folder"
                        #Set properties
                        $identity = "$machinename\$MemberIdentity"
                        $fileSystemRights = "$MemberRight"
                        $type ="Allow"
                        #Create new rule
                        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
                        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
                        $RemAcl.RemoveAccessRule($fileSystemAccessRule)
                        Set-Acl -Path "$DriveSelect`:\$folder" -AclObject $RemAcl
        
                        #command to add member ($loopIdentity) with rights ($loopRight) to folder ($folder)
                        $NewAcl = Get-Acl -Path "$DriveSelect`:\$folder"
                        #Set properties
                        $identity = "$machinename\$loopIdentity"
                        $fileSystemRights = "$loopRight"
                        $type ="Allow"
                        #Create new rule
                        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
                        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
                        # Apply new rule
                        $NewAcl.SetAccessRule($fileSystemAccessRule)
                        Set-Acl -Path "$DriveSelect`:\$folder" -AclObject $NewAcl
                        $OutputBox10.text+="$MemberIdentity is now remediated."
                        # $Global:RemediateFolderChartCountFail +=1
                    }
                    elseif ($MemberIdentity -inotlike $loopIdentity) {
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="$MemberIdentity name is not configured properly."
                        #command to rename member ($MemberIdentity) to name ($loopIdentity)
                        Rename-LocalUser -Name "$MemberIdentity" -NewName "$loopIdentity"
                        $OutputBox10.text+="$MemberIdentity is now remediated." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                    }
                    elseif ($MemberRight -inotlike $loopRight) {
                        # $OutputBox9.ForeColor = 'red'
                        $OutputBox10.text+="$MemberIdentity permissions is not configured properly."
                        #command to edit member ($loopIdentity) rights ($loopRights)
                        $NewAcl = Get-Acl -Path "$DriveSelect`:\$folder"
                        #Set properties
                        $identity = "$machinename\$loopIdentity"
                        $fileSystemRights = "$loopRight"
                        $type ="Allow"
                        #Create new rule
                        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
                        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
                        # Apply new rule
                        $NewAcl.SetAccessRule($fileSystemAccessRule)
                        Set-Acl -Path "$DriveSelect`:\$folder" -AclObject $NewAcl
                        $OutputBox10.text+="$MemberIdentity is now remediated." + "`r`n"
                        # $Global:RemediateFolderChartCountFail +=1
                    }
                    else{
                        # $OutputBox9.ForeColor = 'green'
                        $OutputBox10.text+="$folder is configured properly and does not require remediation." + "`r`n"
                        # $Global:RemediateFolderChartCountPass +=1
                    }           
                    $countfolder++
                }
            }
        }
    }
    catch{
        $OutputBox10.text+="Drive does not exist, please mount, create or rename a new drive." + "`r`n"
    }
    $OutputBox10.text+="Machine remediation has been completed."
}


### Check Windows
Function CheckWindows(){
    $GroupArrayFail =@()
    $GroupArrayPass =@()
    $Global:GroupChartCountFail =0
    $Global:GroupChartCountPass =0
    $Global:FolderChartCountFail =0
    $Global:FolderChartCountPass =0
    $ConfigFile = $global:TxtFile
    $ConfigKeys = @{}
    Get-Content $ConfigFile | ForEach-Object {
    $Keys = $_ -split "="
    $ConfigKeys += @{$Keys[0]=$Keys[1]}
    }
    $OutputBox9.text+="Now checking Groups and Users configurations." + "`r`n"
    foreach($line in Get-Content $global:TxtFile){
        if($line -match "drive="){
            $Global:DriveSelect= $line.split("=")
            $Global:DriveSelect= $Global:DriveSelect[1]
            break
        }
    }
    $countgroup=1
    foreach($line in Get-Content $global:TxtFile){
        $MemberCompConfig=""
        $MemberCompConfig=@()
        if($line -match "group[1234567890]="){
            $grouploop = '$ConfigKeys.group' + $countgroup
            $grouploop = Invoke-Expression $grouploop
            $VariableGroup=net localgroup $grouploop
            $DashCheck=$False
            for($i=0;$i -lt $VariableGroup.length;$i++){
                $LoopItem=[String]$VariableGroup[$i]
                if($i -eq 0){
                    $Alias=$LoopItem.split("     ")
                    $Alias=$Alias[-1]
                    # Write-Host $Alias
                }
                if ($LoopItem.Contains("The command completed successfully.")){
                    $DashCheck=$False
                }
                if($DashCheck){
                    ### Computer config
                    $MemberCompConfig+=$LoopItem
                }
                if($LoopItem.contains("---")){
                    $DashCheck=$True
                }
            }
            ### From config file
            $loopGroup = "$"+ "ConfigKeys.group" + $countgroup
            $loopGroup = Invoke-Expression $loopGroup 
            $MemberConfFile = "$"+ "ConfigKeys.member" + $countgroup
            $MemberConfFile = Invoke-Expression $MemberConfFile
            
            if ($MemberConfFile.contains(",")){
                $MemberConfFile=$MemberConfFile.split(",")
            }
            else{
                $MemberConfFile=@("$MemberConfFile")
            }
            ### compare length: If conf file > computer config -> Missing
            ### compare length: If Comouter Config > Conf file -> Excess accounts = wrong
            $ConfFileLength=$MemberConfFile.length
            # $MemberConfFile
            $CompConfigLength=$MemberCompConfig.length
            # Write-Host $ConfFileLength + "Conf file"
            # Write-Host $CompConfigLength + "Computer"
            if($ConfFileLength -gt $CompConfigLength){
                ###Missing
                for($x=0;$x -lt $ConfFileLength;$x++){
                    $tempItem=$MemberConfFile[$x]
                    if(-Not($tempItem -like $MemberCompConfig)){
                        # $OutputBox9.text+= $tempItem + " is not found in $Alias" + "`r`n"
                        $GroupArrayFail +=@($tempItem + " is not found in $Alias" + "`r`n")
                    }
                }
                # $OutputBox9.text+= "$Alias is not configured properly." + "`r`n"
                $GroupArrayFail +=@("$Alias is not configured properly." + "`r`n")
                $Global:GroupChartCountFail +=1
            }
            elseif($CompConfigLength -gt $ConfFileLength){
                ###Wrong
                for($x=0;$x -lt $CompConfigLength;$x++){
                    $tempItem=$MemberCompConfig[$x]
                    if(-Not($tempItem -like $MemberConfFile)){ 
                        # $OutputBox9.text+=$tempItem + " is an excess account in $Alias" + "`r`n"
                        $GroupArrayFail +=@($tempItem + " is an excess account in $Alias" + "`r`n")
                    }
                }
                # $OutputBox9.text+= "$Alias is not configured properly." + "`r`n"
                $GroupArrayFail +=@("$Alias is not configured properly." + "`r`n")
                $Global:GroupChartCountFail +=1
            }
            else{
                $ConfigCorrect=$True
                for($x=0;$x -lt $ConfFileLength;$x++){
                    $tempItem=$MemberConfFile[$x]
                    if($MemberCompConfig -like $tempItem){
                        ### correct
                    }
                    else{
                        $ConfigCorrect=$False
                        ###Missing
                        # Write-Host "lol" + $tempItem
                        # Write-Host "lol2" + $MemberCompConfig
                        if(-Not($tempItem -like $MemberCompConfig)){
                            # $OutputBox9.text+= $tempItem + " is not found in $Alias" + "`r`n"
                            $GroupArrayFail +=@($tempItem + " is not found in $Alias" + "`r`n")
                        }
                    }
                }
                for($y=0;$y -lt $CompConfigLength;$y++){
                    $tempItem=$MemberCompConfig[$y]
                    if(-Not($MemberConfFile -contains $tempItem)){
                        # $OutputBox9.text+=$tempItem + " is not suppose to be in $Alias" + "`r`n"
                        $GroupArrayFail +=@($tempItem + " is not supposed to be in $Alias" + "`r`n")
                    }
                }
                #Scoring with comparison (if/else)
                if (($Alias.contains($loopGroup)) -and ($ConfigCorrect)) {
                    # $OutputBox9.text+="$Alias is configured properly." + "`r`n"
                    $GroupArrayPass +=@("$Alias is configured properly." + "`r`n")
                    $Global:GroupChartCountPass += 1
                }
                else{
                    # $OutputBox9.text+="$Alias is not configured properly." + "`r`n"
                    $GroupArrayFail +=@("$Alias is not configured properly." + "`r`n")
                    $Global:GroupChartCountFail += 1
                }
            }
            $countgroup++ 
        }
    }
    $OutputBox9.text+="Displaying correct configurations." + "`r`n"
    #print out right lines in green
    foreach($pass in $GroupArrayPass){
        # $outputbox9.ForeColor = 'green'
        # $OutputBox9.forecolor="Green"
        # $outputBox.SelectionStart = 1
        # $outputBox.SelectionLength = 5
        # $outputBox.SelectionColor = 'red'
        $OutputBox9.text+=$pass
    }
    $OutputBox9.text+="End of pass section."

    $OutputBox9.text+=" " + "`r`n" + "`r`n"
    $OutputBox9.text+="Displaying incorrect configurations." + "`r`n"
    #print out wrong lines in red
    foreach($fail in $GroupArrayFail){
        # $outputbox9.ForeColor = 'red'
        $OutputBox9.text+=$fail
    }
    $OutputBox9.text+="End of fail section."

    ### make sure got space in between outputs
    $OutputBox9.text+=" " + "`r`n" + "`r`n" 
    $OutputBox9.text+="Now checking folders configurations" + "`r`n"

    function GetFolder ($folder) {
        $ExpressionGetFolder='(get-acl ' + $Global:DriveSelect + ':\' + $folder + ').access | Select-Object `
        @{Label="Identity";Expression={$_.IdentityReference}}, `
        @{Label="Right";Expression={$_.FileSystemRights}}'
        $Global:DriveStatus=$True
        Write-Output $Global:DriveStatus | Out-Null
        Write-Output $Global:DriveSelect":\$folder"

        try{
            if (Test-Path -Path $Global:DriveSelect":\$folder"){
                Invoke-Expression $ExpressionGetFolder
                $Global:DriveStatus=$True
            }
            else{
                $Global:DriveStatus=$False
            }
        }
        catch{
            $Global:DriveStatus=$False
        }
    }

    $countfolder=1
    foreach($line in Get-Content $global:TxtFile){
        if($line -match "folder[1234567890]="){
            $folderloop = '$folder= $ConfigKeys.folder' + $countfolder
            $folderloop = Invoke-Expression $folderloop
            $VariableFolder=GetFolder $folder
            if ($Global:DriveStatus -eq $True){
                for($i=0;$i -lt $VariableFolder.length;$i++){
                    $LoopItemFolder=[String]$VariableFolder[$i]
                    if($i -eq 1){
                        $Identity=$LoopItemFolder.split("\")
                        $Identity=$Identity[1]
                        $Identity=$Identity.split(";")
                        $Admin=$Identity[0]
                        $AdminRight=$Identity[1]
                        $AdminRight=$AdminRight.Split("=")
                        $AdminRight=$AdminRight[1]
                        $AdminRight=$AdminRight -replace '}',''
                    }
                    if ($i -eq 2){
                        $Identity=$LoopItemFolder.split("\")
                        $Identity=$Identity[1]
                        $Identity=$Identity.split(";")
                        $MemberIdentity=$Identity[0]
                        $Right=$Identity[1]
                        $Right=$Right.Split("=")
                        $Right=$Right[1]
                        $MemberRight=$Right -replace '}',''
                    }
                }
                #Scoring with comparison (if/else)
                $loopAdmin = "$"+ "ConfigKeys.admin" + $countfolder
                $loopAdmin = Invoke-Expression $loopAdmin 
                $loopFolder = "$"+ "ConfigKeys.folder" + $countfolder
                $loopFolder = Invoke-Expression $loopFolder
                $loopRight = "$"+ "ConfigKeys.right" + $countfolder
                $loopRight = Invoke-Expression $loopRight
                $loopIdentity = "$"+ "ConfigKeys.identity" + $countfolder
                $loopIdentity = Invoke-Expression $loopIdentity
                # Write-Host "start"
                # $Admin
                # $ConfigKeys.folderadmin
                # $AdminRight
                # $loopAdmin
                # Write-Host "End"
            }
            if($Global:DriveStatus -eq $False) {
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="$folder path is not configured properly" + "`r`n"
                $Global:FolderChartCountFail +=1
            }
            elseif (($Admin -inotlike $ConfigKeys.folderadmin) -and ($AdminRight -inotlike $loopAdmin)){
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="Admin name and permissions is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1      
            }
            elseif ($Admin -inotlike $ConfigKeys.folderadmin){
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="Admin name is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1      
            }
            elseif ($AdminRight -inotlike $loopAdmin){
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="Admin permissions is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1    
            }
            elseif (($MemberIdentity -inotlike $loopIdentity) -and  ($MemberRight -inotlike $loopRight)){
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="$MemberIdentity name and permissions is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1
            }
            elseif ($MemberIdentity -inotlike $loopIdentity) {
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="$MemberIdentity name is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1
            }
            elseif ($MemberRight -inotlike $loopRight) {
                # $OutputBox9.ForeColor = 'red'
                $OutputBox9.text+="$MemberIdentity permissions is not configured properly." + "`r`n"
                $Global:FolderChartCountFail +=1
            }
            else{
                # $OutputBox9.ForeColor = 'green'
                $OutputBox9.text+="$folder is configured properly" + "`r`n"
                $Global:FolderChartCountPass +=1
            }           
            $countfolder++
        }
    }
    $OutputBox9.text+="End of folder check section." + "`r`n" + "`r`n"
    $OutputBox9.text+="Machine configuration check has been completed."
}




############ End of Background Code ########################
### Load Class
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Windows.Forms.Application]::EnableVisualStyles()
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

#### Create a Windows Form with PowerShell 
############ Start of GUI ############ 
###Global Variable
# $global:HTMLFile

### Choose Which Section to test
$Global:SectionArray=""
$Global:SectionArray=@(0,0,0,0,0,0,0)

### 1.1 & 1.2
$Global:SpecificSection=""
$Global:SpecificSection=@()

### Used to check pass, fail, error and unknown
$Global:ArrayOfArrays=""
$Global:ArrayOfArrays=@()

$Global:ArrayOfArraysPg3=""
$Global:ArrayOfArraysPg3=@()

$Global:FirstFile=""
$Global:FirstFile=@()
$Global:FirstFileArray=""
$Global:FirstFileArray=@()


$Global:SecondFile=""
$Global:SecondFile=@()
$Global:SecondFileArray=""
$Global:SecondFileArray=@()

$Global:Remediate=$False

$Global:HiglightPg4=""
$Global:HiglightPg4=@()

$Global:OutputBoxName=""

$Global:AllCorrect=$False

###Functions
### Hide Page 1
Function HidePage1(){
    $Label.Visible=$False
    $Label1.Visible=$False
    $Option1.Visible=$False
    $Option2.Visible=$False
    $Option3.Visible=$False
    $Option4.Visible=$False
    $Option5.Visible=$False
    $Option6.Visible=$False
    $Button1.Visible=$False
    $Button2.Visible=$False
    $Button3.Visible=$False
    $Button4.Visible=$False
    $Button5.Visible=$False
    $Button6.Visible=$False
    
}
Function ShowPage1(){
    $Label.Visible=$True
    $Label1.Visible=$True
    $Option1.Visible=$True
    $Option2.Visible=$True
    $Option3.Visible=$True
    $Option4.Visible=$True
    $Option5.Visible=$True
    $Option6.Visible=$True
    $Button1.Visible=$True
    $Button2.Visible=$True
    $Button3.Visible=$True
    $Button4.Visible=$True
    $Button5.Visible=$True
    $Button6.Visible=$True
    
}

Function HidePage2(){
    $LabelPg2.Visible=$False
    $LabelOptionPg2.Visible=$False
    $LabelDescPg2.Visible=$False
    $SelectionLabelPg2.Visible=$False
    $SelectFileButtonPg2.Visible=$False
    $ContinueButtonPg2.Visible=$False
    $BackButtonPg2.Visible=$False
    $NoCheckBoxSelection.Visible=$False
}

Function ShowPage2(){
    $LabelPg2.Visible=$True
    $LabelOptionPg2.Visible=$True
    $LabelDescPg2.Visible=$True
    $SelectionLabelPg2.Visible=$True
    $SelectFileButtonPg2.Visible=$True
    $BackButtonPg2.Visible=$True

    
}

Function HidePage3(){
    $IdentifyingFail.Visible=$False
    $ResultsLabel.Visible=$False
    $OutcomeResult.Visible=$False
    $OutcomeResult2.Visible=$False
    $IdentifyComplete.Visible=$False
    $Global:OutputBox.Visible=$False
    $StartIdentifyingFailButton.Visible=$False
    $BackButtonPg3.Visible=$False
    $ReturnToHomePg3.Visible=$False
    try{
        $Global:Chart1Pg3.Visible=$False
        $Global:Chart2Pg3.Visible=$False
    }
    catch{}
    
}

Function ShowPage3(){
    $IdentifyingFail.Visible=$True
    $ResultsLabel.Visible=$True
    $Global:OutputBox.Visible=$True
    $StartIdentifyingFailButton.Visible=$True
    $BackButtonPg3.Visible=$True
    $Global:OutputBox.Location= New-Object System.Drawing.Size(20,100)
    $Global:OutputBox.Size= New-Object System.Drawing.Size(880,700)
    
}

Function HidePage4(){
    $LabelPg4.Visible=$False
    $LabelOptionPg4.Visible=$False
    $LabelDescPg4.Visible=$False
    $SelectFileButton.Visible=$False
    $SelectionLabel.Visible=$False
    $BackButtonPg4.Visible=$False
    $LegendLabelPg4.Visible=$False
    $ChooseLabelPg4.Visible=$False
    $NoCheckBoxSelection.Visible=$False
    $ContinueButton.Visible=$False
    $CheckAllBoxes.Visible=$False
    $CheckBox1.Visible=$False
    $CheckBox1_1.Visible=$False
    $CheckBox1_2.Visible=$False

    $CheckBox2.Visible=$False
    $CheckBox2_2.Visible=$False
    $CheckBox2_3_1.Visible=$False
    $CheckBox2_3_2.Visible=$False
    $CheckBox2_3_4.Visible=$False
    $CheckBox2_3_6.Visible=$False
    $CheckBox2_3_7.Visible=$False
    $CheckBox2_3_8.Visible=$False
    $CheckBox2_3_9.Visible=$False
    $CheckBox2_3_10.Visible=$False
    $CheckBox2_3_11.Visible=$False
    $CheckBox2_3_15.Visible=$False
    $CheckBox2_3_17.Visible=$False

    $CheckBox5.Visible=$False

    $CheckBox9.Visible=$False
    $CheckBox9_1.Visible=$False
    $CheckBox9_2.Visible=$False
    $CheckBox9_3.Visible=$False

    $CheckBox17.Visible=$False
    $CheckBox17_1.Visible=$False
    $CheckBox17_2.Visible=$False
    $CheckBox17_3.Visible=$False
    $CheckBox17_5.Visible=$False
    $CheckBox17_6.Visible=$False
    $CheckBox17_7.Visible=$False
    $CheckBox17_8.Visible=$False
    $CheckBox17_9.Visible=$False

    $CheckBox18.Visible=$False
    $CheckBox18_1_1.Visible=$False
    $CheckBox18_1_2.Visible=$False
    $CheckBox18_2.Visible=$False
    $CheckBox18_3.Visible=$False
    $CheckBox18_4.Visible=$False
    $CheckBox18_5_4.Visible=$False
    $CheckBox18_5_8.Visible=$False
    $CheckBox18_5_11.Visible=$False
    $CheckBox18_5_14.Visible=$False
    $CheckBox18_5_21.Visible=$False
    $CheckBox18_5_23_2.Visible=$False
    $CheckBox18_6.Visible=$False
    $CheckBox18_8_3.Visible=$False
    $CheckBox18_8_4.Visible=$False
    $CheckBox18_8_7.Visible=$False
    $CheckBox18_8_14.Visible=$False
    $CheckBox18_8_21.Visible=$False
    $CheckBox18_8_22_1.Visible=$False
    $CheckBox18_8_28.Visible=$False
    $CheckBox18_8_34_6.Visible=$False
    $CheckBox18_8_36.Visible=$False
    $CheckBox18_8_37.Visible=$False
    $CheckBox18_9_4.Visible=$False
    $CheckBox18_9_5.Visible=$False
    $CheckBox18_9_6.Visible=$False
    $CheckBox18_9_8.Visible=$False
    $CheckBox18_9_10_1.Visible=$False
    $CheckBox18_9_14.Visible=$False
    $CheckBox18_9_15.Visible=$False
    $CheckBox18_9_16.Visible=$False
    $CheckBox18_9_17.Visible=$False
    $CheckBox18_9_18.Visible=$False
    $CheckBox18_9_27_1.Visible=$False
    $CheckBox18_9_27_2.Visible=$False
    $CheckBox18_9_27_3.Visible=$False
    $CheckBox18_9_27_4.Visible=$False
    $CheckBox18_9_31.Visible=$False
    $CheckBox18_9_36.Visible=$False
    $CheckBox18_9_46.Visible=$False
    $CheckBox18_9_47_4.Visible=$False
    $CheckBox18_9_47_5_1.Visible=$False
    $CheckBox18_9_47_5_3.Visible=$False
    $CheckBox18_9_47_9.Visible=$False
    $CheckBox18_9_47_12.Visible=$False
    $CheckBox18_9_47_14.Visible=$False
    $CheckBox18_9_58.Visible=$False
    $CheckBox18_9_65_2.Visible=$False
    $CheckBox18_9_65_3_3.Visible=$False
    $CheckBox18_9_65_3_9.Visible=$False
    $CheckBox18_9_65_3_11.Visible=$False
    $CheckBox18_9_66.Visible=$False
    $CheckBox18_9_67.Visible=$False
    $CheckBox18_9_75.Visible=$False
    $CheckBox18_9_81.Visible=$False
    $CheckBox18_9_85_1.Visible=$False
    $CheckBox18_9_85_2.Visible=$False
    $CheckBox18_9_87.Visible=$False
    $CheckBox18_9_89.Visible=$False
    $CheckBox18_9_90.Visible=$False
    $CheckBox18_9_91.Visible=$False
    $CheckBox18_9_100.Visible=$False
    $CheckBox18_9_102_1.Visible=$False
    $CheckBox18_9_102_2.Visible=$False
    $CheckBox18_9_104.Visible=$False
    $CheckBox18_9_105_2.Visible=$False
    $CheckBox18_9_108_1.Visible=$False
    $CheckBox18_9_108_2.Visible=$False
    $CheckBox18_9_108_4.Visible=$False

    $CheckBox19.Visible=$False
    $CheckBox19_1_3.Visible=$False
    $CheckBox19_5_1.Visible=$False
    $CheckBox19_7_4.Visible=$False
    $CheckBox19_7_8.Visible=$False
    $CheckBox19_7_28.Visible=$False
    $CheckBox19_7_43.Visible=$False
    $invisibleObjectPg4.Visible=$False
    ### reset all checkboxes

    $CheckAllBoxes.Checked=$False
    $CheckBox1.Checked=$False
    $CheckBox1_1.Checked=$False
    $CheckBox1_2.Checked=$False

    $CheckBox2.checked=$False
    $CheckBox2_2.Checked=$False
    $CheckBox2_3_1.Checked=$False
    $CheckBox2_3_2.Checked=$False
    $CheckBox2_3_4.Checked=$False
    $CheckBox2_3_6.Checked=$False
    $CheckBox2_3_7.Checked=$False
    $CheckBox2_3_8.Checked=$False
    $CheckBox2_3_9.Checked=$False
    $CheckBox2_3_10.Checked=$False
    $CheckBox2_3_11.Checked=$False
    $CheckBox2_3_15.Checked=$False
    $CheckBox2_3_17.Checked=$False

    $CheckBox5.checked=$False

    $CheckBox9.checked=$False
    $CheckBox9_1.Checked=$False
    $CheckBox9_2.Checked=$False
    $CheckBox9_3.Checked=$False

    $CheckBox17.checked=$False
    $CheckBox17_1.Checked=$False
    $CheckBox17_2.Checked=$False
    $CheckBox17_3.Checked=$False
    $CheckBox17_5.Checked=$False
    $CheckBox17_6.Checked=$False
    $CheckBox17_7.Checked=$False
    $CheckBox17_8.Checked=$False
    $CheckBox17_9.Checked=$False

    $CheckBox18.checked=$False
    $CheckBox18_1_1.checked=$False
    $CheckBox18_1_2.checked=$False
    $CheckBox18_2.checked=$False
    $CheckBox18_3.checked=$False
    $CheckBox18_4.checked=$False
    $CheckBox18_5_4.checked=$False
    $CheckBox18_5_8.checked=$False
    $CheckBox18_5_11.checked=$False
    $CheckBox18_5_14.checked=$False
    $CheckBox18_5_21.checked=$False
    $CheckBox18_5_23_2.checked=$False
    $CheckBox18_6.checked=$False
    $CheckBox18_8_3.checked=$False
    $CheckBox18_8_4.checked=$False
    $CheckBox18_8_7.checked=$False
    $CheckBox18_8_14.checked=$False
    $CheckBox18_8_21.checked=$False
    $CheckBox18_8_22_1.checked=$False
    $CheckBox18_8_28.checked=$False
    $CheckBox18_8_34_6.checked=$False
    $CheckBox18_8_36.checked=$False
    $CheckBox18_8_37.checked=$False
    $CheckBox18_9_4.checked=$False
    $CheckBox18_9_5.checked=$False
    $CheckBox18_9_6.checked=$False
    $CheckBox18_9_8.checked=$False
    $CheckBox18_9_10_1.checked=$False
    $CheckBox18_9_14.checked=$False
    $CheckBox18_9_15.checked=$False
    $CheckBox18_9_16.checked=$False
    $CheckBox18_9_17.checked=$False
    $CheckBox18_9_18.checked=$False
    $CheckBox18_9_27_1.checked=$False
    $CheckBox18_9_27_2.checked=$False
    $CheckBox18_9_27_3.checked=$False
    $CheckBox18_9_27_4.checked=$False
    $CheckBox18_9_31.checked=$False
    $CheckBox18_9_36.checked=$False
    $CheckBox18_9_46.checked=$False
    $CheckBox18_9_47_4.checked=$False
    $CheckBox18_9_47_5_1.checked=$False
    $CheckBox18_9_47_5_3.checked=$False
    $CheckBox18_9_47_9.checked=$False
    $CheckBox18_9_47_12.checked=$False
    $CheckBox18_9_47_14.checked=$False
    $CheckBox18_9_58.checked=$False
    $CheckBox18_9_65_2.checked=$False
    $CheckBox18_9_65_3_3.checked=$False
    $CheckBox18_9_65_3_9.checked=$False
    $CheckBox18_9_65_3_11.checked=$False
    $CheckBox18_9_66.checked=$False
    $CheckBox18_9_67.checked=$False
    $CheckBox18_9_75.checked=$False
    $CheckBox18_9_81.checked=$False
    $CheckBox18_9_85_1.checked=$False
    $CheckBox18_9_85_2.checked=$False
    $CheckBox18_9_87.checked=$False
    $CheckBox18_9_89.checked=$False
    $CheckBox18_9_90.checked=$False
    $CheckBox18_9_91.checked=$False
    $CheckBox18_9_100.checked=$False
    $CheckBox18_9_102_1.checked=$False
    $CheckBox18_9_102_2.checked=$False
    $CheckBox18_9_104.checked=$False
    $CheckBox18_9_105_2.checked=$False
    $CheckBox18_9_108_1.checked=$False
    $CheckBox18_9_108_2.checked=$False
    $CheckBox18_9_108_4.checked=$False

    $CheckBox19.Checked=$False
    $CheckBox19_1_3.Checked=$False
    $CheckBox19_5_1.Checked=$False
    $CheckBox19_7_4.Checked=$False
    $CheckBox19_7_8.Checked=$False
    $CheckBox19_7_28.Checked=$False
    $CheckBox19_7_43.Checked=$False
    
}

Function ShowPage4(){
    $LabelPg4.Visible=$True
    $LabelOptionPg4.Visible=$True
    $LabelDescPg4.Visible=$True
    $SelectFileButton.Visible=$True
    $SelectionLabel.Visible=$True
    $BackButtonPg4.Visible=$True
}

Function HidePage5(){
    $Global:OutputBox.Visible=$False
    $StartRemediationPg5.Visible=$False
    $BackButtonPg5.Visible=$False
    $StartRemediationButtonPg5.Visible=$False
    $ReturnToHomePg5.Visible=$False
    $FinishRemediationPg5.Visible=$False
    $Remediation.Visible=$False
}

Function ShowPage5(){
    $Global:OutputBox.Visible=$True
    $StartRemediationPg5.Visible=$True
    $BackButtonPg5.Visible=$True
    $StartRemediationButtonPg5.Visible=$True
    $Global:OutputBox.Location= New-Object System.Drawing.Size(80,100)
    $Global:OutputBox.Size= New-Object System.Drawing.Size(1150,700)
    $Remediation.Visible=$True
}

Function HidePage6(){
    $LabelPg6.Visible=$False
    $Label1Page6.Visible=$False
    $Label1APage6.Visible=$False
    $SelectFile1ButtonPg6.Visible=$False
    $Label2Page6.Visible=$False
    $Label1BPage6.Visible=$False
    $SelectFile2ButtonPg6.Visible=$False
    $BackButtonPg6.Visible=$False
    $ContinueButtonPg6.Visible=$False
    $LabelDescPg6.Visible=$False

}

Function ShowPage6(){
    $LabelPg6.Visible=$True
    $Label1Page6.Visible=$True
    $Label1APage6.Visible=$True
    $SelectFile1ButtonPg6.Visible=$True
    $Label2Page6.Visible=$True
    $Label1BPage6.Visible=$True
    $SelectFile2ButtonPg6.Visible=$True
    $BackButtonPg6.Visible=$True
    $LabelDescPg6.Visible=$True

}

Function HidePage7(){
    $Global:OutputBox.Visible=$False
    $CompareLabelPg7.Visible=$False
    $CompareLabel1APg7.Visible=$False
    $CompareLabel1BPg7.Visible=$False
    $FinishRemediationPg7.Visible=$False
    $FinishRemediationAPg7.Visible=$False
    $CompareLabelButtonPg7.Visible=$False
    $BackButtonPg7.Visible=$False
    $ReturnToHomePg7.Visible=$Falseputbox1
    try{
        $Global:Chart.Visible=$False
        $Global:Chart2.Visible = $False
        $Global:Chart3.Visible = $False
        $Global:Chart4.Visible = $False
    }
    catch{}
    $Global:OutputBox1.Visible=$False
    $OutcomeResult3.Visible=$False
    $OutcomeResult4.Visible=$False
    $OutcomeResult5.Visible=$False
    $OutcomeResult6.Visible=$False

}

Function ShowPage7(){
    $FinishRemediationPg7.Visible=$False
    $FinishRemediationAPg7.Visible=$False
    $FinishRemediationPg7.Text =""
    $Global:OutputBox.Size = New-Object System.Drawing.Size(600,400)
    $Global:OutputBox.Location = New-Object System.Drawing.Size(220,100)
    $Global:OutputBox.Visible=$True
    $CompareLabelPg7.Visible=$True
    $CompareLabel1APg7.Visible=$True
    $CompareLabel1BPg7.Visible=$True
    $CompareLabelButtonPg7.Visible=$True
    $BackButtonPg7.Visible=$True
    $Global:OutputBox1.Visible=$True
    $Global:OutputBox1.Size = New-Object System.Drawing.Size(600,400)
    $Global:OutputBox1.Location = New-Object System.Drawing.Size(950,100)

}

Function HidePage9(){
    $SelectFileButtonPg9.Visible=$False
    $BackButtonPg9.Visible=$False
    $Back2HomeButtonPg9.Visible=$False
    $LabelDescPg9.Visible=$False
    $LabelOptionPg9.Visible=$False
    Try{
        $Global:Chart5.Visible = $False
        $Global:Chart6.Visible = $False
        $EditTXTPg9.Visible=$False
        $CancelEditPg9.visible=$False
        $SaveTXTPg9.visible=$False
        $OutputBox9.Visible=$False
        $ReadmeBox9.Visible=$False
        $SelectionLabelPg9.Visible=$False
        $ContinueButtonPg9.Visible=$False
    }
    catch{}

}
Function ShowPage9(){
    $SelectFileButtonPg9.Visible=$True
    $BackButtonPg9.Visible=$True
    $LabelDescPg9.Visible=$True
    $LabelOptionPg9.Visible=$True
}

Function HidePage10(){
    $SelectFileButtonPg10.Visible=$False
    $BackButtonPg10.Visible=$False
    $Back2HomeButtonPg10.Visible=$False
    $LabelDescPg10.Visible=$False
    $LabelOptionPg10.Visible=$False
    Try{
        $EditTXTPg10.Visible=$False
        $CancelEditPg10.visible=$False
        $SaveTXTPg10.visible=$False
        $OutputBox10.Visible=$False
        $ReadmeBox10.Visible=$False
        $SelectionLabelPg10.Visible=$False
        $ContinueButtonPg10.Visible=$False
    }
    catch{}

}
function ShowPage10(){
    $SelectFileButtonPg10.Visible=$True
    $BackButtonPg10.Visible=$True
    $LabelDescPg10.Visible=$True
    $SelectionLabelPg10.Visible=$True
    $LabelOptionPg10.Visible=$True
}




### Create Screen form
$main_form = New-Object System.Windows.Forms.Form

### Title and size of window
$main_form.Text ='WinSA'
$main_form.Width = 1030
$main_form.Height = 800
$main_form.WindowState = 'Maximized'

### Make the window automatically stretch
# $main_form.AutoSize = $True
$main_form.maximumsize = New-Object System.Drawing.Size(1920,970)
$main_form.MinimumSize  = New-Object System.Drawing.Size(800,800)
$main_form.startposition = "centerscreen"
$main_form.autoscroll  = $true;
# $main_form.FormBorderStyle = 'FixedSingle'
$main_form.MaximizeBox = $True
$main_form.MinimizeBox = $True
# $main_form.FormBorderStyle  = [System.Windows.Forms.FormBorderStyle]::Fixed3D




############ Page 1: Start Page ############

### Create a label element on the form
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Welcome to WinSA"
$Label.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 35, [System.Drawing.FontStyle]::Bold)
### Location of text on the windows form
$Label.Anchor="Top"
$Label.Location  = New-Object System.Drawing.Point(135,10)
$Label.AutoSize = $True

### Add the Label to the form 
$main_form.Controls.Add($Label)

### Label 1
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "What action would you like to perform?"
$Label1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 25)
$Label1.Location  = New-Object System.Drawing.Point(5,80)
$Label1.AutoSize = $True
$main_form.Controls.Add($Label1)



#### Selection Check Boxes

### Option 1
$Option1 = New-Object System.Windows.Forms.Label
$Option1.Text = "2. Check Computer Security Status from CIS Benchmark Results"
$Option1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option1.Location  = New-Object System.Drawing.Point(5,205) 
$Option1.AutoSize = $True
$main_form.Controls.Add($Option1)
## Option 1 Button
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(1000,205)  
$Button1.Size = New-Object System.Drawing.Size(380,35)
$Button1.Text = "Review CIS Benchmark Results"
$Button1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button1)
### On Button click
$Button1.Add_Click({
    ## Goes to Page 2
    ShowPage2
    HidePage1
})

### Option 2
$Option2 = New-Object System.Windows.Forms.Label
$Option2.Text = "3. Remediate selected Sections of CIS Benchmark"
$Option2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option2.Location  = New-Object System.Drawing.Point(5,275) 
$Option2.AutoSize = $True
$main_form.Controls.Add($Option2)
## Option 2 Button
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Size(1000,275) 
$Button2.Size = New-Object System.Drawing.Size(380,35)
$Button2.Text = "Remediate selected Sections"
$Button2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button2)
### On Button click
$Button2.Add_Click({
    ### Goes to Page 4, Option 2
    ShowPage4
    HidePage1
    
})

### Option 3
$Option3 = New-Object System.Windows.Forms.Label
$Option3.Text = "4. Compare the results of before and after remediation"
$Option3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option3.Location  = New-Object System.Drawing.Point(5,345) 
$Option3.AutoSize = $True
$main_form.Controls.Add($Option3)
## Option 3 Button
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Location = New-Object System.Drawing.Size(1000,345) 
$Button3.Size = New-Object System.Drawing.Size(380,35)
$Button3.Text = "Compare Results"
$Button3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button3)
### On Button click
$Button3.Add_Click({
    ShowPage6
    HidePage1

})

### Option 4
$Option4 = New-Object System.Windows.Forms.Label
$Option4.Text = "1. Produce CIS Benchmark Result for this Computer"
$Option4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option4.Location  = New-Object System.Drawing.Point(5,135) 
$Option4.AutoSize = $True
$main_form.Controls.Add($Option4)
## Option 4 Button
$Button4 = New-Object System.Windows.Forms.Button
$Button4.Location = New-Object System.Drawing.Size(1000,135) 
$Button4.Size = New-Object System.Drawing.Size(380,35)
$Button4.Text = "Produce CIS Benchmark Result"
$Button4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button4)
### On Button click
$Button4.Add_Click({
    ### Dynamically opens CIS benchmark
    $location=""
    $location+=Get-ChildItem -Path C:\users -Include "CIS-CAT-Lite-v4.19.0" -recurse
    $location = $location -split " "
    $location = $location -join " "
    $location+="\Assessor\Assessor-GUI.exe"
    try{
    & $location
    }
    catch{
        ###child_form
        $Child_formPg8 = New-Object System.Windows.Forms.Form
        ### Title and size of window
        $Child_formPg8.Text ='CIS Benchmark Missing from computer'
        $Child_formPg8.Width = 400
        $Child_formPg8.Height = 200
        $Child_formPg8.startposition = "centerscreen"
        $Child_formPg8.maximumsize = New-Object System.Drawing.Size(400,200)
        $Child_formPg8.MinimumSize  = New-Object System.Drawing.Size(400,200)
        $Child_formPg8.FormBorderStyle = 'Fixed3D'
        $Child_formPg8.MaximizeBox = $false

        ### Label
        $LabelChildPg8 = New-Object System.Windows.Forms.Label
        $LabelChildPg8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
        $LabelChildPg8.Location  = New-Object System.Drawing.Point(5,10)
        $LabelChildPg8.Visible=$True
        $LabelChildPg8.text="Make sure CIS-CAT-Lite-v4.19.0 is downloaded `r`non this computer."
        $LabelChildPg8.AutoSize = $True
        $Child_formPg8.Controls.Add($LabelChildPg8)
        

        ### Proceed with remediation button
        $OkButtonChildPg8 = New-Object System.Windows.Forms.Button
        $OkButtonChildPg8.Location = New-Object System.Drawing.Size(290,125)
        $OkButtonChildPg8.Size = New-Object System.Drawing.Size(85,26)
        $OkButtonChildPg8.Text = "Ok"
        $OkButtonChildPg8.Visible=$True
        $Child_formPg8.Controls.Add($OkButtonChildPg8)
        $OkButtonChildPg8.Add_Click({
            ## Show Label
            $Child_formPg8.close()
        })
        $Child_formPg8.ShowDialog()


    }
})

### Option 5
$Option5 = New-Object System.Windows.Forms.Label
$Option5.Text = "5. Check Computer Configuration by selecting a configuration file"
$Option5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option5.Location  = New-Object System.Drawing.Point(5,410)
$Option5.AutoSize = $True
$main_form.Controls.Add($Option5)
## Option 5 Button
$Button5 = New-Object System.Windows.Forms.Button
$Button5.Location = New-Object System.Drawing.Size(1000,410)
$Button5.Size = New-Object System.Drawing.Size(380,35)
$Button5.Text = "Check Computer Configuration"
$Button5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button5)
### On Button click
$Button5.Add_Click({
    ###
    ShowPage9
    HidePage1

})

### Option 6
$Option6 = New-Object System.Windows.Forms.Label
$Option6.Text = "6. Remediate Computer Configuration by selecting a configuration file"
$Option6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
$Option6.Location  = New-Object System.Drawing.Point(5,475)
$Option6.AutoSize = $True
$main_form.Controls.Add($Option6)
## Option 6 Button
$Button6 = New-Object System.Windows.Forms.Button
$Button6.Location = New-Object System.Drawing.Size(1000,475)
$Button6.Size = New-Object System.Drawing.Size(380,35)
$Button6.Text = "Remediate Computer Configuration"
$Button6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 13)
$main_form.Controls.Add($Button6)
### On Button click
$Button6.Add_Click({
    ###
    ShowPage10
    HidePage1

})


############ Page 2: Option 1 ############ 
### Label option
$LabelOptionPg2 = New-Object System.Windows.Forms.Label
$LabelOptionPg2.Text = "Check Computer Security Status from CIS Benchmark Results"
$LabelOptionPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
$LabelOptionPg2.Location  = New-Object System.Drawing.Point(5,10)
$LabelOptionPg2.AutoSize = $True
$main_form.Controls.Add($LabelOptionPg2)
$LabelOptionPg2.Visible=$False

#Description
$LabelDescPg2 = New-Object System.Windows.Forms.Label
$LabelDescPg2.Text = "Select a CIS Benchmark result that is of HTML file type to assess."
$LabelDescPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$LabelDescPg2.Location  = New-Object System.Drawing.Point(5,55)
$LabelDescPg2.AutoSize = $True
$main_form.Controls.Add($LabelDescPg2)
$LabelDescPg2.Visible=$False

### Label
$LabelPg2 = New-Object System.Windows.Forms.Label
$LabelPg2.Text = "Select a file to Assess"
$LabelPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 18, [System.Drawing.FontStyle]::Bold)
$LabelPg2.Location  = New-Object System.Drawing.Point(5,90)
$LabelPg2.AutoSize = $True
$main_form.Controls.Add($LabelPg2)
$LabelPg2.Visible=$False

### Select Label
$SelectionLabelPg2 = New-Object System.Windows.Forms.Label
$SelectionLabelPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$SelectionLabelPg2.Location  = New-Object System.Drawing.Point(5,125)
$SelectionLabelPg2.AutoSize = $True
$main_form.Controls.Add($SelectionLabelPg2)
$SelectionLabelPg2.Visible=$False

### Select Button
$SelectFileButtonPg2 = New-Object System.Windows.Forms.Button
$SelectFileButtonPg2.Location = New-Object System.Drawing.Size(870,690)
$SelectFileButtonPg2.Size = New-Object System.Drawing.Size(125,45)
$SelectFileButtonPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$SelectFileButtonPg2.Text = "Select File"
$SelectFileButtonPg2.Anchor = 'Bottom, Right'
$main_form.Controls.Add($SelectFileButtonPg2)
$SelectFileButtonPg2.Visible=$False
### On Button click
$SelectFileButtonPg2.Add_Click({
    
    $initialDirectory = [Environment]::GetFolderPath('Desktop')

    $OpenFileDialogPg2 = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialogPg2.InitialDirectory = $initialDirectory

    $OpenFileDialogPg2.Filter = 'CIS Results (*.html)|*.html'

    $OpenFileDialogPg2.Multiselect = $False
    $AcceptableFile=$False
    $response = $OpenFileDialogPg2.ShowDialog()
    ### Appropriate file type choosen
    if ($response -eq 'OK'){ 
        ###Write-Host 'You selected the file:' $OpenFileDialog.FileName ### File name
        $AcceptableFile=$True
    }
    $global:HTMLFile=[String]$OpenFileDialogPg2.FileName
    
    if ($AcceptableFile){
        $SelectionLabelPg2.Text = "You have selected: " + $global:HTMLFile
        $ContinueButtonPg2.Visible=$True
        

    }
    else{
        $SelectionLabelPg2.Text ="You have not selected a file"
        $ContinueButtonPg2.Visible=$False
        

    }
})

$BackButtonPg2 = New-Object System.Windows.Forms.Button
$BackButtonPg2.Location = New-Object System.Drawing.Size(40,690)
$BackButtonPg2.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg2.Text = "Back"
$BackButtonPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg2.Visible=$False
$BackButtonPg2.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg2)
### On Button click
$BackButtonPg2.Add_Click({
    $SelectionLabelPg2.Text = ""
    ### Goes to Page 2
    HidePage2
    ShowPage1

})

$ContinueButtonPg2 = New-Object System.Windows.Forms.Button
$ContinueButtonPg2.Location = New-Object System.Drawing.Size(1050,690)
$ContinueButtonPg2.Size = New-Object System.Drawing.Size(125,45)
$ContinueButtonPg2.Text = "Continue"
$ContinueButtonPg2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueButtonPg2.Anchor = 'Bottom, Right'
$ContinueButtonPg2.Visible=$False
$main_form.Controls.Add($ContinueButtonPg2)
$ContinueButtonPg2.Add_Click({
    $SelectionLabelPg2.Text = ""
    ShowPage3
    HidePage2
})


############ Page 3: Option 1 ############ 


$IdentifyingFail = New-Object System.Windows.Forms.Label
$IdentifyingFail.Text = "Computer Security Status of selected CIS benchmark"
$IdentifyingFail.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
$IdentifyingFail.Location  = New-Object System.Drawing.Point(5,10)
$IdentifyingFail.AutoSize = $True
$IdentifyingFail.Visible=$False
$main_form.Controls.Add($IdentifyingFail)

$ResultsLabel = New-Object System.Windows.Forms.Label
$ResultsLabel.Text = "Results"
$ResultsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 19, [System.Drawing.FontStyle]::Bold)
$ResultsLabel.Location  = New-Object System.Drawing.Point(15,64)
$ResultsLabel.AutoSize = $True
$ResultsLabel.Visible=$False
$main_form.Controls.Add($ResultsLabel)

### First OutputBox
$Global:OutputBox = New-Object System.Windows.Forms.TextBox
$Global:OutputBox.Location = New-Object System.Drawing.Size(220,90)
$Global:OutputBox.Size = New-Object System.Drawing.Size(600,270)
$Global:OutputBox.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$Global:OutputBox.ReadOnly=$True
$Global:OutputBox.Multiline = $True
$Global:OutputBox.Visible=$False
$Global:OutputBox.Scrollbars = "Vertical" 
$main_form.Controls.Add($Global:OutputBox)

### Second OutputBox
$Global:OutputBox1 = New-Object System.Windows.Forms.TextBox
$Global:OutputBox1.Location = New-Object System.Drawing.Size(970,90)
$Global:OutputBox1.Size = New-Object System.Drawing.Size(600,400)
$Global:OutputBox1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$Global:OutputBox1.ReadOnly=$True
$Global:OutputBox1.Multiline = $True
$Global:OutputBox1.Visible=$False
$Global:OutputBox1.Scrollbars = "Vertical" 
$main_form.Controls.Add($Global:OutputBox1)

$StartIdentifyingFailButton = New-Object System.Windows.Forms.Button
$StartIdentifyingFailButton.Location = New-Object System.Drawing.Size(430,695) 
$StartIdentifyingFailButton.Size = New-Object System.Drawing.Size(125,45)
$StartIdentifyingFailButton.Text = "Start Identification"
$StartIdentifyingFailButton.anchor="Bottom"
$StartIdentifyingFailButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$StartIdentifyingFailButton.Visible=$False
$main_form.Controls.Add($StartIdentifyingFailButton)
### On Button click
$StartIdentifyingFailButton.Add_Click({
    ### Hide buttons
    $BackButtonPg3.Visible=$False
    $StartIdentifyingFailButton.Visible=$False
    ### Set variables
    $Global:SectionArray=@(1,2,5,9,17,18,19)
    $Global:SpecificSection=@("1.1","1.2","2.2","2.3.1","2.3.2","2.3.4","2.3.6","2.3.7","2.3.8","2.3.9","2.3.10","2.3.11","2.3.15","2.3.17","5","9.1","9.2","9.3",
    "17.1","17.2","17.3","17.5","17.6","17.7","17.8","17.9","18.1.1","18.1.2","18.2","18.3","18.4","18.5.4","18.5.8","18.5.11","18.5.14","18.5.21","18.5.23.2",
    "18.6","18.8.3","18.8.4","18.8.7","18.8.14","18.8.21","18.8.22.1", "18.8.28", "18.8.34.6","18.8.36","18.8.37","18.9.4","18.9.5","18.9.6","18.9.8","18.9.10.1",
    "18.9.14","18.9.15", "18.9.16", "18.9.17", "18.9.18", "18.9.27.1", "18.9.27.2","18.9.27.3","18.9.27.4","18.9.31","18.9.36","18.9.46","18.9.47.4","18.9.47.5.1", 
    "18.9.47.5.3", "18.9.47.9", "18.9.47.12", "18.9.47.14","18.9.58","18.9.65.2","18.9.65.3.3","18.9.65.3.9","18.9.65.3.11","18.9.66","18.9.67","18.9.75","18.9.81", 
    "18.9.85.1","18.9.85.2","18.9.87","18.9.89","18.9.90","18.9.91","18.9.100","18.9.102.1","18.9.102.2","18.9.104","18.9.105.2","18.9.108.1","18.9.108.2","18.9.108.4", 
    "19.1.3", "19.5.1", "19.7.4", "19.7.8", "19.7.28", "19.7.43")
    
    
    
    ### Run Main Program
    $Global:FailTestArrayFinal=""
    $Global:FailTestArrayFinal=@()
    $Global:DetailedArray=""
    $Global:DetailedArray=@()
    $Global:ArrayOfArrays=""
    $Global:ArrayOfArrays=@()
    $Global:ArrayOfArraysPg3=""
    $Global:ArrayOfArraysPg3=@()


    $Global:ReadFile=$True
    ## Not Remediating
    $Global:Remediate=$False
    $Global:OutputBox.text=""
        $Global:OutputBoxName="Global:OutputBox"
    Write-Output $Global:OutputBoxName | Out-Null

    StartAssessment
    
    ####start here 
    
    ### Object from HTML file
    $Pass=0
    $Fail=0
    $ErrorValue=0
    $Unknown=0
    if (-Not ($Global:AllCorrect)){
        for($i=0;$i -lt $Global:ArrayOfArrays.Length;$i+=5){
            $Pass+= $Global:ArrayOfArrays[$i+1]
            $Fail+= $Global:ArrayOfArrays[$i+2]
            $ErrorValue+= $Global:ArrayOfArrays[$i+3]
            $Unknown+= $Global:ArrayOfArrays[$i+4]
    
            $TempObject=[PSCustomObject]@{
                Title = $Global:ArrayOfArrays[$i]
                Pass  = $Global:ArrayOfArrays[$i+1]
                Fail  = $Global:ArrayOfArrays[$i+2]
                Error = $Global:ArrayOfArrays[$i+3]
                unknown =$Global:ArrayOfArrays[$i+4]
            }
            $Global:OutputBox.text+="`r`n Section: " + $Global:ArrayOfArrays[$i] + "`r`n"
            $Global:OutputBox.text+="Pass:    " + $Global:ArrayOfArrays[$i+1] + "`r`n"
            $Global:OutputBox.text+="Fail:    " + $Global:ArrayOfArrays[$i+2] + "`r`n"
            $Global:OutputBox.text+="Error:   " + $Global:ArrayOfArrays[$i+3] + "`r`n"
            $Global:OutputBox.text+="Unknown:  " + $Global:ArrayOfArrays[$i+4] + "`r`n"
            $Global:OutputBox.text+="`r`n"
            $Global:ArrayOfArraysPg3+=$TempObject
        }
    }

    
    $Global:OutputBox.text+="`r`n Assessment Completed! `r`n"
    ### $FinishRemediationPg7.Text = "Assessment Completed!"


    #### First Pie chart (Overall Pie chart)

    $DataArray = @("Passed", "Failed", "Error", "Unknown")
    $DataValues=@($Pass,$Fail,$ErrorValue,$Unknown)
    # create chart object
    $Global:Chart1Pg3 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $Global:Chart1Pg3.Width = 670
    $Global:Chart1Pg3.Height = 310
    $Global:Chart1Pg3.Left = 20
    $Global:Chart1Pg3.Top = 20
    $Global:Chart1Pg3.Location = New-Object System.Drawing.Size(1000,90)
    $Global:Chart1Pg3.Visible = $True
    ### Title
    $ChartTitle1Pg3 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $ChartTitle1Pg3.Text = $global:HTMLFile
    $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
    $ChartTitle1Pg3.Font =$Font
    $Global:Chart1Pg3.Titles.Add($ChartTitle1Pg3)

    # chart colour palette (must match data array order)
    $Global:Chart1Pg3.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
    $Global:Chart1Pg3.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red, [System.Drawing.Color]::Gold, [System.Drawing.Color]::Brown )

    # create a chartarea to draw on and add to chart
    $Global:Chart1Pg3Area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    # $Global:Chart1Pg3Area.Backgroundcolor="Orange"
    $Global:Chart1Pg3.ChartAreas.Add($Global:Chart1Pg3Area)

    # add data to chart
    [void]$Global:Chart1Pg3.Series.Add("Data")
    $Global:Chart1Pg3.Series["Data"].Points.DataBindXY($DataArray, $DataValues)
    $Global:Chart1Pg3.Series["Data"].ChartType = "Pie"
    $Global:Chart1Pg3.Series["Data"]["PieLabelStyle"] = "Outside"
    $Global:Chart1Pg3.Series["Data"]["PieDrawingStyle"] = "Concave"
    $Global:Chart1Pg3.Series["Data"]["PieLineColor"] = "Black"
    ($Global:Chart1Pg3.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
    $Global:Chart1Pg3.Series["Data"]['PieLabelStyle'] = 'Disabled'

    # Legend
    $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $Legend.IsEquallySpacedItems = $True
    $Legend.BorderColor = 'Black'
    $Global:Chart1Pg3.Legends.Add($Legend)
    $Global:Chart1Pg3.Series["Data"].LegendText = "#VALX (#PERCENT)"
    $main_form.Controls.Add($Global:Chart1Pg3)


    
    #### Second Pie chart (Incorrect configuration based on Sections)
    $Section1=0
    $Section2=0
    $Section5=0
    $Section9=0
    $Section17=0
    $Section18=0
    $Section19=0
    for ($i=0;$i -lt $Global:ArrayOfArraysPg3.length;$i++){
        if($i -eq 0){$Section1=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 1){$Section2=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 2){$Section5=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 3){$Section9=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 4){$Section17=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 5){$Section18=$Global:ArrayOfArraysPg3[$i].Fail}
        if($i -eq 6){$Section19=$Global:ArrayOfArraysPg3[$i].Fail}
    }


    $DataArray = @("Section 1", "Section 2", "Section 5", "Section 9", "Section 17", "Section 18", "Section 19")
    $DataValues=@($Section1,$Section2,$Section5,$Section9,$Section17,$Section18,$Section19)

    $Global:Chart2Pg3 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $Global:Chart2Pg3.Width = 670
    $Global:Chart2Pg3.Height = 310
    $Global:Chart2Pg3.Left = 20
    $Global:Chart2Pg3.Top = 20
    $Global:Chart2Pg3.Location = New-Object System.Drawing.Size(1000,470)
    $Global:Chart2Pg3.Visible = $True
    ### Title
    $ChartTitle2Pg3 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $ChartTitle2Pg3.Text = 'Incorrect Configuration from each Section'
    $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
    $ChartTitle2Pg3.Font =$Font
    $Global:Chart2Pg3.Titles.Add($ChartTitle2Pg3)

    # chart colour palette (must match data array order)
    $Global:Chart2Pg3.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None ###brown, gold, red ,green
    $Global:Chart2Pg3.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Blue, [System.Drawing.Color]::Purple, [System.Drawing.Color]::HotPink, [System.Drawing.Color]::Red, [System.Drawing.Color]::Orange )

    # create a chartarea to draw on and add to chart
    $Global:Chart2Pg3Area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    # $Global:Chart2Pg3Area.Backgroundcolor="Orange"
    $Global:Chart2Pg3.ChartAreas.Add($Global:Chart2Pg3Area)

    # add data to chart
    [void]$Global:Chart2Pg3.Series.Add("Data")
    $Global:Chart2Pg3.Series["Data"].Points.DataBindXY($DataArray, $DataValues)
    $Global:Chart2Pg3.Series["Data"].ChartType = "Pie"
    $Global:Chart2Pg3.Series["Data"]["PieLabelStyle"] = "Outside"
    $Global:Chart2Pg3.Series["Data"]["PieDrawingStyle"] = "Concave"
    $Global:Chart2Pg3.Series["Data"]["PieLineColor"] = "Black"
    ($Global:Chart2Pg3.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
    $Global:Chart2Pg3.Series["Data"]['PieLabelStyle'] = 'Disabled'

    # Legend
    $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $Legend.IsEquallySpacedItems = $True
    $Legend.BorderColor = 'Black'
    $Global:Chart2Pg3.Legends.Add($Legend)
    $Global:Chart2Pg3.Series["Data"].LegendText = "#VALX (#PERCENT)"
    $main_form.Controls.Add($Global:Chart2Pg3)


    #### End of code


    ####end here
    ### Hide Problems
    Write-Output "$Global:SectionArray" | Out-Null
    Write-Output $Global:SpecificSection |Out-Null
    Write-Output $Global:ReadFile |Out-Null
    Write-Output $Global:Remediate |Out-Null
    Write-Output $Global:FailTestArrayFinal | Out-Null
    Write-Output $Global:DetailedArray | Out-Null
    ### Reinitialise variables
    #$Global:ArrayOfArrays
    $Global:SpecificSection=@()
    $Global:SectionArray=@(0,0,0,0,0,0,0)
    ### Show buttons
    $OutcomeResult.text+=" Overall Results: `r`n Number of Pass: " + $Pass + " `r`n Number of Fails: " + $Fail + "`r`n Number of Error: " + $ErrorValue + "`r`n Number of Unknown: " + $Unknown
    $OutcomeResult.Visible=$True
    $OutcomeResult2.text+=" Fails from each section: `r`n Section 1: " + $Section1 + " `r`n Section 2: " + $Section2 + "`r`n Section 5: " + $Section5 + "`r`n Section 9: " + $Section9 + "`r`n Section 17: " + $Section17 + "`r`n Section 18: " + $Section18 + "`r`n Section 19: " + $Section19
    $OutcomeResult2.Visible=$True
    $IdentifyComplete.Visible=$True
    $ReturnToHomePg3.Visible=$True

})

$OutcomeResult = New-Object System.Windows.Forms.Label
$OutcomeResult.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult.Location  = New-Object System.Drawing.Point(1700,100)
$OutcomeResult.AutoSize = $True
$OutcomeResult.Visible=$False
$main_form.Controls.Add($OutcomeResult)

$OutcomeResult2 = New-Object System.Windows.Forms.Label
$OutcomeResult2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult2.Location = New-Object System.Drawing.Point(1700,480)
$OutcomeResult2.AutoSize = $True
$OutcomeResult2.Visible=$False
$main_form.Controls.Add($OutcomeResult2)

$IdentifyComplete = New-Object System.Windows.Forms.Label
$IdentifyComplete.Text = "Identify Failure Completed!"
$IdentifyComplete.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 15)
$IdentifyComplete.Location  = New-Object System.Drawing.Point(565,70)
$IdentifyComplete.ForeColor='red'
$IdentifyComplete.AutoSize = $True
$IdentifyComplete.Visible=$False
$main_form.Controls.Add($IdentifyComplete)

$ReturnToHomePg3 = New-Object System.Windows.Forms.Button
$ReturnToHomePg3.Location = New-Object System.Drawing.Size(15,700) 
$ReturnToHomePg3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ReturnToHomePg3.Size = New-Object System.Drawing.Size(125,45)
$ReturnToHomePg3.Text = "Back to Home Page"
$ReturnToHomePg3.Anchor="Bottom" 
$ReturnToHomePg3.Visible=$False
$main_form.Controls.Add($ReturnToHomePg3)
### On Button click
$ReturnToHomePg3.Add_Click({
    ### Goes to Page 1

    $Global:OutputBox.text=""
    $OutcomeResult.text=""
    $OutcomeResult2.text=""
    HidePage3
    ShowPage1

})

$BackButtonPg3 = New-Object System.Windows.Forms.Button
$BackButtonPg3.Location = New-Object System.Drawing.Size(16,695)
$BackButtonPg3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg3.Size = New-Object System.Drawing.Size(125,45) 
$BackButtonPg3.Text = "Back"
$BackButtonPg3.Visible=$False
$BackButtonPg3.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg3)
### On Button click
$BackButtonPg3.Add_Click({
    ### Goes to Page 1
    HidePage3
    ShowPage2

})


############ Page 4: Option 2 ############

### Form

### Label
$LabelOptionPg4 = New-Object System.Windows.Forms.Label
$LabelOptionPg4.Text = "Remediate Selected Sections of CIS Benchmark"
$LabelOptionPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
### Location of text on the windows form
$LabelOptionPg4.Location  = New-Object System.Drawing.Point(5,10)
$LabelOptionPg4.AutoSize = $True
$main_form.Controls.Add($LabelOptionPg4)
$LabelOptionPg4.Visible=$False

### Label
$LabelDescPg4 = New-Object System.Windows.Forms.Label
$LabelDescPg4.Text = "Select a CIS Benchmark result that is of HTML file type to remediate"
$LabelDescPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
### Location of text on the windows form
$LabelDescPg4.Location  = New-Object System.Drawing.Point(5,55)
$LabelDescPg4.AutoSize = $True
$main_form.Controls.Add($LabelDescPg4)
$LabelDescPg4.Visible=$False


### Label
$LabelPg4 = New-Object System.Windows.Forms.Label
$LabelPg4.Text = "Select a file to Remediate"
$LabelPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 18, [System.Drawing.FontStyle]::Bold)
$LabelPg4.Location  = New-Object System.Drawing.Point(5,90)
$LabelPg4.AutoSize = $True
$main_form.Controls.Add($LabelPg4)
$LabelPg4.Visible=$False


#### Hidden Label for error
$NoCheckBoxSelection= New-Object System.Windows.Forms.Label
$NoCheckBoxSelection.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 18)
$NoCheckBoxSelection.Location  = New-Object System.Drawing.Point(1100,170)
$NoCheckBoxSelection.Text = "You must select at least 1 Selection"
$NoCheckBoxSelection.ForeColor='red'
$NoCheckBoxSelection.AutoSize = $True
$main_form.Controls.Add($NoCheckBoxSelection)
$NoCheckBoxSelection.Visible=$False

#### Legend label
$LegendLabelPg4= New-Object System.Windows.Forms.Label
$LegendLabelPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16, [System.Drawing.FontStyle]::Underline)
$LegendLabelPg4.Location  = New-Object System.Drawing.Point(550,170)
$LegendLabelPg4.Text = "Incorrect sections are highlighted in Yellow"
$LegendLabelPg4.AutoSize = $True
$main_form.Controls.Add($LegendLabelPg4)
$LegendLabelPg4.Visible=$False

### Select Label This is for page 4
$SelectionLabel = New-Object System.Windows.Forms.Label
$SelectionLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$SelectionLabel.Location  = New-Object System.Drawing.Point(5,130)
$SelectionLabel.AutoSize = $True
$main_form.Controls.Add($SelectionLabel)
$SelectionLabel.Visible=$False

### Continue Button This is for page 4
$ContinueButton = New-Object System.Windows.Forms.Button
$ContinueButton.Location = New-Object System.Drawing.Size(990,690)
$ContinueButton.Size = New-Object System.Drawing.Size(125,45) 
$ContinueButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueButton.Text = "Continue"
$ContinueButton.Anchor = 'Bottom, Right'
$ContinueButton.Visible=$False
$main_form.Controls.Add($ContinueButton)

    $ContinueButton.Add_Click({
        $BackButtonPg4.Visible=$False
        ### Check which checkbox has been selected.
        if ($CheckBox1.Checked){
            $Global:SectionArray[0]=1
            # Write-Host 'Selected1' ### File name 
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox1_1.Checked){
            $Global:SectionArray[0]=1
            $Global:SpecificSection+="1.1" 
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox1_2.Checked){
            $Global:SectionArray[0]=1
            $Global:SpecificSection+="1.2"
            $NoCheckBoxSelection.Visible=$False
        }
        
        ##Section 2
        if ($CheckBox2.Checked){
            $Global:SectionArray[1]=2
            # Write-Host 'Selected2' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_2.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.2" 
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_1.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_2.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_4.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_6.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.6"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_7.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.7"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_8.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.8"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_9.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.9"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_10.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.10"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_11.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.11"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_15.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.15"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox2_3_17.Checked){
            $Global:SectionArray[1]=2
            $Global:SpecificSection+="2.3.17"
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if ($CheckBox5.Checked){
            $Global:SectionArray[2]=5
            $Global:SpecificSection+="5"
            # Write-Host 'Selected5' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if ($CheckBox9.Checked){
            $Global:SectionArray[3]=9
            # Write-Host 'Selected9' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox9_1.Checked){
            $Global:SectionArray[3]=9
            $Global:SpecificSection+="9.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox9_2.Checked){
            $Global:SectionArray[3]=9
            $Global:SpecificSection+="9.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox9_3.Checked){
            $Global:SectionArray[3]=9
            $Global:SpecificSection+="9.3"
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if ($CheckBox17.Checked){
            $Global:SectionArray[4]=17
            # Write-Host 'Selected17' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_1.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_1.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_2.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_3.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_5.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.5"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_6.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.6"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_7.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.7"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_8.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.8"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox17_9.Checked){
            $Global:SectionArray[4]=17
            $Global:SpecificSection+="17.9"
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if ($CheckBox18.Checked){
            $Global:SectionArray[5]=18
            # Write-Host 'Selected18' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_1_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.1.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_1_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.1.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_3.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_8.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.8"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_11.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.11"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_14.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.14"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_21.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.21"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_5_23_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.5.23.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_6.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.6"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_3.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_7.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.7"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_14.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.14"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_21.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.21"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_22_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.22.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_28.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.28"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_34_6.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.34.6"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_36.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.36"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_8_37.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.8.37"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_5.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.5"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_6.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.6"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_8.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.8"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_10_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.10.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_14.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.14"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_15.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.15"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_16.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.16"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_17.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.17"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_18.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.18"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_27_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.27.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_27_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.27.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_27_3.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.27.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_27_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.27.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_31.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.31"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_36.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.36"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_46.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.46"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_5_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.5.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_5_3.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.5.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_9.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.9"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_12.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.12"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_47_14.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.47.14"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_58.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.58"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_65_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.65.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_65_3_3.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.65.3.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_65_3_9.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.65.3.9"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_65_3_11.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.65.3.11"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_66.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.66"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_67.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.67"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_75.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.75"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_81.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.81"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_85_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.85.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_85_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.85.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_87.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.87"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_89.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.89"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_90.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.90"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_91.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.91"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_100.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.100"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_102_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.102.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_102_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.102.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_104.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.104"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_105_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.105.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_108_1.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.108.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_108_2.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.108.2"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox18_9_108_4.Checked){
            $Global:SectionArray[5]=18
            $Global:SpecificSection+="18.9.108.4"
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if ($CheckBox19.Checked){
            $Global:SectionArray[6]=19
            # Write-Host 'Selected19' ### File name
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_1_3.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.1.3"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_5_1.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.5.1"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_7_4.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.7.4"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_7_8.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.7.8"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_7_28.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.7.28"
            $NoCheckBoxSelection.Visible=$False
        }
        if ($CheckBox19_7_43.Checked){
            $Global:SectionArray[6]=19
            $Global:SpecificSection+="19.7.43"
            $NoCheckBoxSelection.Visible=$False
        }
    
    
        if (($Global:SectionArray[0] -eq 0) -and ($Global:SectionArray[1] -eq 0) -and ($Global:SectionArray[2] -eq 0) -and ($Global:SectionArray[3] -eq 0) -and ($Global:SectionArray[4] -eq 0) -and ($Global:SectionArray[5] -eq 0) -and ($Global:SectionArray[6] -eq 0)){
            $Global:SectionArrayAll0=$True
        }
        else{
            $Global:SectionArrayAll0=$False
        }
        ###Debug
        #### Write-Host $Global:SpecificSection.Length
        #### Write-Host $Global:SectionArrayAll0
        ### No checkbox has been selected
        if (($Global:SpecificSection.Length -ne 0) -and (-Not ($Global:SectionArrayAll0))){
            $SelectionLabel.Text = ""
            $Global:OutputBox.text=""
            HidePage4
            ShowPage5
            ### Write-Host "Look at this array" $Global:SectionArray
        }
        else{
            ### Error message that states no checkbox have been selected
            $NoCheckBoxSelection.Visible=$True
            $BackButtonPg4.Visible=$True

            ###child_form
            $Child_formPg4 = New-Object System.Windows.Forms.Form
            ### Title and size of window
            $Child_formPg4.Text ='Missing Input'
            $Child_formPg4.Width = 400
            $Child_formPg4.Height = 200
            $Child_formPg4.startposition = "centerscreen"
            $Child_formPg4.maximumsize = New-Object System.Drawing.Size(400,200)
            $Child_formPg4.MinimumSize  = New-Object System.Drawing.Size(400,200)
            $Child_formPg4.FormBorderStyle = 'Fixed3D'
            $Child_formPg4.MaximizeBox = $false

            ### Label
            $LabelChildPg4 = New-Object System.Windows.Forms.Label
            $LabelChildPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
            $LabelChildPg4.Location  = New-Object System.Drawing.Point(5,10)
            $LabelChildPg4.Visible=$True
            $LabelChildPg4.text="You must select at least 1 Selection"
            $LabelChildPg4.AutoSize = $True
            $Child_formPg4.Controls.Add($LabelChildPg4)
            

            ### Proceed with remediation button
            $OkButtonChildPg4 = New-Object System.Windows.Forms.Button
            $OkButtonChildPg4.Location = New-Object System.Drawing.Size(290,125)
            $OkButtonChildPg4.Size = New-Object System.Drawing.Size(85,26)
            $OkButtonChildPg4.Text = "Ok"
            $OkButtonChildPg4.Visible=$True
            $Child_formPg4.Controls.Add($OkButtonChildPg4)
            $OkButtonChildPg4.Add_Click({
                ## Show Label
                $Child_formPg4.close()
            })
            $Child_formPg4.ShowDialog()

    
        }
    })
    
    ### Label
    $ChooseLabelPg4= New-Object System.Windows.Forms.Label
    $ChooseLabelPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 18, [System.Drawing.FontStyle]::Bold)
    $ChooseLabelPg4.Location  = New-Object System.Drawing.Point(5,170)
    $ChooseLabelPg4.Text = "Choose Section/s to remediate"
    $ChooseLabelPg4.ForeColor='Black'
    $ChooseLabelPg4.AutoSize = $True
    $main_form.Controls.Add($ChooseLabelPg4)
    $ChooseLabelPg4.Visible=$False

    ### Select 
    $CheckAllBoxes = New-Object System.Windows.Forms.CheckBox
    $CheckAllBoxes.Location = New-Object System.Drawing.Size(400,175) ### difference of 20 will do
    $CheckAllBoxes.Size = New-Object System.Drawing.Size(120,23) 
    $CheckAllBoxes.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckAllBoxes.Text = "Select All"
    $CheckAllBoxes.AutoSize=$True
    $CheckAllBoxes.Visible=$False
    $main_form.Controls.Add($CheckAllBoxes)
    $CheckAllBoxes.Add_Click({
        if ($CheckAllBoxes.Checked){
            $CheckBox1.Checked=$True
            $CheckBox1_1.Checked=$True
            $CheckBox1_2.Checked=$True

            $CheckBox2.Checked=$True
            $CheckBox2_2.Checked=$True
            $CheckBox2_3_1.Checked=$True
            $CheckBox2_3_2.Checked=$True
            $CheckBox2_3_4.Checked=$True
            $CheckBox2_3_6.Checked=$True
            $CheckBox2_3_7.Checked=$True
            $CheckBox2_3_8.Checked=$True
            $CheckBox2_3_9.Checked=$True
            $CheckBox2_3_10.Checked=$True
            $CheckBox2_3_11.Checked=$True
            $CheckBox2_3_15.Checked=$True
            $CheckBox2_3_17.Checked=$True

            $CheckBox5.Checked=$True

            $CheckBox9.Checked=$True
            $CheckBox9_1.Checked=$True
            $CheckBox9_2.Checked=$True
            $CheckBox9_3.Checked=$True

            $CheckBox17.Checked=$True
            $CheckBox17_1.Checked=$True
            $CheckBox17_2.Checked=$True
            $CheckBox17_3.Checked=$True
            $CheckBox17_5.Checked=$True
            $CheckBox17_6.Checked=$True
            $CheckBox17_7.Checked=$True
            $CheckBox17_8.Checked=$True
            $CheckBox17_9.Checked=$True

            $CheckBox18.Checked=$True
            $CheckBox18_1_1.checked=$True
            $CheckBox18_1_2.checked=$True
            $CheckBox18_2.checked=$True
            $CheckBox18_3.checked=$True
            $CheckBox18_4.checked=$True
            $CheckBox18_5_4.checked=$True
            $CheckBox18_5_8.checked=$True
            $CheckBox18_5_11.checked=$True
            $CheckBox18_5_14.checked=$True
            $CheckBox18_5_21.checked=$True
            $CheckBox18_5_23_2.checked=$True
            $CheckBox18_6.checked=$True
            $CheckBox18_8_3.checked=$True
            $CheckBox18_8_4.checked=$True
            $CheckBox18_8_7.checked=$True
            $CheckBox18_8_14.checked=$True
            $CheckBox18_8_21.checked=$True
            $CheckBox18_8_22_1.checked=$True
            $CheckBox18_8_28.checked=$True
            $CheckBox18_8_34_6.checked=$True
            $CheckBox18_8_36.checked=$True
            $CheckBox18_8_37.checked=$True
            $CheckBox18_9_4.checked=$True
            $CheckBox18_9_5.checked=$True
            $CheckBox18_9_6.checked=$True
            $CheckBox18_9_8.checked=$True
            $CheckBox18_9_10_1.checked=$True
            $CheckBox18_9_14.checked=$True
            $CheckBox18_9_15.checked=$True
            $CheckBox18_9_16.checked=$True
            $CheckBox18_9_17.checked=$True
            $CheckBox18_9_18.checked=$True
            $CheckBox18_9_27_1.checked=$True
            $CheckBox18_9_27_2.checked=$True
            $CheckBox18_9_27_3.checked=$True
            $CheckBox18_9_27_4.checked=$True
            $CheckBox18_9_31.checked=$True
            $CheckBox18_9_36.checked=$True
            $CheckBox18_9_46.checked=$True
            $CheckBox18_9_47_4.checked=$True
            $CheckBox18_9_47_5_1.checked=$True
            $CheckBox18_9_47_5_3.checked=$True
            $CheckBox18_9_47_9.checked=$True
            $CheckBox18_9_47_12.checked=$True
            $CheckBox18_9_47_14.checked=$True
            $CheckBox18_9_58.checked=$True
            $CheckBox18_9_65_2.checked=$True
            $CheckBox18_9_65_3_3.checked=$True
            $CheckBox18_9_65_3_9.checked=$True
            $CheckBox18_9_65_3_11.checked=$True
            $CheckBox18_9_66.checked=$True
            $CheckBox18_9_67.checked=$True
            $CheckBox18_9_75.checked=$True
            $CheckBox18_9_81.checked=$True
            $CheckBox18_9_85_1.checked=$True
            $CheckBox18_9_85_2.checked=$True
            $CheckBox18_9_87.checked=$True
            $CheckBox18_9_89.checked=$True
            $CheckBox18_9_90.checked=$True
            $CheckBox18_9_91.checked=$True
            $CheckBox18_9_100.checked=$True
            $CheckBox18_9_102_1.checked=$True
            $CheckBox18_9_102_2.checked=$True
            $CheckBox18_9_104.checked=$True
            $CheckBox18_9_105_2.checked=$True
            $CheckBox18_9_108_1.checked=$True
            $CheckBox18_9_108_2.checked=$True
            $CheckBox18_9_108_4.checked=$True

            $CheckBox19.Checked=$True
            $CheckBox19_1_3.Checked=$True
            $CheckBox19_5_1.Checked=$True
            $CheckBox19_7_4.Checked=$True
            $CheckBox19_7_8.Checked=$True
            $CheckBox19_7_28.Checked=$True
            $CheckBox19_7_43.Checked=$True
        }
        else{
            $CheckBox1.Checked=$False
            $CheckBox1_1.Checked=$False
            $CheckBox1_2.Checked=$False

            $CheckBox2.checked=$False
            $CheckBox2_2.Checked=$False
            $CheckBox2_3_1.Checked=$False
            $CheckBox2_3_2.Checked=$False
            $CheckBox2_3_4.Checked=$False
            $CheckBox2_3_6.Checked=$False
            $CheckBox2_3_7.Checked=$False
            $CheckBox2_3_8.Checked=$False
            $CheckBox2_3_9.Checked=$False
            $CheckBox2_3_10.Checked=$False
            $CheckBox2_3_11.Checked=$False
            $CheckBox2_3_15.Checked=$False
            $CheckBox2_3_17.Checked=$False

            $CheckBox5.checked=$False

            $CheckBox9.checked=$False
            $CheckBox9_1.Checked=$False
            $CheckBox9_2.Checked=$False
            $CheckBox9_3.Checked=$False

            $CheckBox17.checked=$False
            $CheckBox17_1.Checked=$False
            $CheckBox17_2.Checked=$False
            $CheckBox17_3.Checked=$False
            $CheckBox17_5.Checked=$False
            $CheckBox17_6.Checked=$False
            $CheckBox17_7.Checked=$False
            $CheckBox17_8.Checked=$False
            $CheckBox17_9.Checked=$False

            $CheckBox18.checked=$False
            $CheckBox18_1_1.checked=$False
            $CheckBox18_1_2.checked=$False
            $CheckBox18_2.checked=$False
            $CheckBox18_3.checked=$False
            $CheckBox18_4.checked=$False
            $CheckBox18_5_4.checked=$False
            $CheckBox18_5_8.checked=$False
            $CheckBox18_5_11.checked=$False
            $CheckBox18_5_14.checked=$False
            $CheckBox18_5_21.checked=$False
            $CheckBox18_5_23_2.checked=$False
            $CheckBox18_6.checked=$False
            $CheckBox18_8_3.checked=$False
            $CheckBox18_8_4.checked=$False
            $CheckBox18_8_7.checked=$False
            $CheckBox18_8_14.checked=$False
            $CheckBox18_8_21.checked=$False
            $CheckBox18_8_22_1.checked=$False
            $CheckBox18_8_28.checked=$False
            $CheckBox18_8_34_6.checked=$False
            $CheckBox18_8_36.checked=$False
            $CheckBox18_8_37.checked=$False
            $CheckBox18_9_4.checked=$False
            $CheckBox18_9_5.checked=$False
            $CheckBox18_9_6.checked=$False
            $CheckBox18_9_8.checked=$False
            $CheckBox18_9_10_1.checked=$False
            $CheckBox18_9_14.checked=$False
            $CheckBox18_9_15.checked=$False
            $CheckBox18_9_16.checked=$False
            $CheckBox18_9_17.checked=$False
            $CheckBox18_9_18.checked=$False
            $CheckBox18_9_27_1.checked=$False
            $CheckBox18_9_27_2.checked=$False
            $CheckBox18_9_27_3.checked=$False
            $CheckBox18_9_27_4.checked=$False
            $CheckBox18_9_31.checked=$False
            $CheckBox18_9_36.checked=$False
            $CheckBox18_9_46.checked=$False
            $CheckBox18_9_47_4.checked=$False
            $CheckBox18_9_47_5_1.checked=$False
            $CheckBox18_9_47_5_3.checked=$False
            $CheckBox18_9_47_9.checked=$False
            $CheckBox18_9_47_12.checked=$False
            $CheckBox18_9_47_14.checked=$False
            $CheckBox18_9_58.checked=$False
            $CheckBox18_9_65_2.checked=$False
            $CheckBox18_9_65_3_3.checked=$False
            $CheckBox18_9_65_3_9.checked=$False
            $CheckBox18_9_65_3_11.checked=$False
            $CheckBox18_9_66.checked=$False
            $CheckBox18_9_67.checked=$False
            $CheckBox18_9_75.checked=$False
            $CheckBox18_9_81.checked=$False
            $CheckBox18_9_85_1.checked=$False
            $CheckBox18_9_85_2.checked=$False
            $CheckBox18_9_87.checked=$False
            $CheckBox18_9_89.checked=$False
            $CheckBox18_9_90.checked=$False
            $CheckBox18_9_91.checked=$False
            $CheckBox18_9_100.checked=$False
            $CheckBox18_9_102_1.checked=$False
            $CheckBox18_9_102_2.checked=$False
            $CheckBox18_9_104.checked=$False
            $CheckBox18_9_105_2.checked=$False
            $CheckBox18_9_108_1.checked=$False
            $CheckBox18_9_108_2.checked=$False
            $CheckBox18_9_108_4.checked=$False

            $CheckBox19.Checked=$False
            $CheckBox19_1_3.Checked=$False
            $CheckBox19_5_1.Checked=$False
            $CheckBox19_7_4.Checked=$False
            $CheckBox19_7_8.Checked=$False
            $CheckBox19_7_28.Checked=$False
            $CheckBox19_7_43.Checked=$False


        }
    })
    
    
    ### Check box Section 1
    $CheckBox1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox1.Location = New-Object System.Drawing.Size(30,205) ### difference of 20 will do
    $CheckBox1.Size = New-Object System.Drawing.Size(120,23) 
    $CheckBox1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox1.Text = "Section 1"
    $CheckBox1.AutoSize=$True
    $CheckBox1.Visible=$False
    $main_form.Controls.Add($CheckBox1)
    $CheckBox1.Add_Click({
        if ($CheckBox1.Checked){
            $CheckBox1_1.Checked=$True
            $CheckBox1_2.Checked=$True
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox1_1.Checked=$False
            $CheckBox1_2.Checked=$False
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    ### Check box Section 1.1
    $CheckBox1_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox1_1.Location = New-Object System.Drawing.Size(50,235) ### difference of 20 will do
    $CheckBox1_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox1_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox1_1.Text = "1.1 Password Policy"
    $CheckBox1_1.AutoSize=$True
    $CheckBox1_1.Visible=$False
    $main_form.Controls.Add($CheckBox1_1)
    $CheckBox1_1.Add_Click({
        if($CheckBox1_2.Checked){
            $CheckBox1.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox1_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox1.Checked=$False
        }
    
    })
    
    ### Check box Section 1.2
    $CheckBox1_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox1_2.Location = New-Object System.Drawing.Size(525,235) ### difference of 20 will do
    $CheckBox1_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox1_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox1_2.Text = "1.2 Account Lockout Policy"
    $CheckBox1_2.AutoSize=$True
    $CheckBox1_2.Visible=$False
    $main_form.Controls.Add($CheckBox1_2)
    $CheckBox1_2.Add_Click({
        if($CheckBox1_1.Checked){
            $CheckBox1.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox1_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox1.Checked=$False
        }
    
    })
    
    
    ### Check box Section 2
    $CheckBox2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2.Location = New-Object System.Drawing.Size(30,265) 
    $CheckBox2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2.Text = "Section 2"
    $CheckBox2.AutoSize=$True
    $CheckBox2.Visible=$False
    $main_form.Controls.Add($CheckBox2)
    $CheckBox2.Add_Click({
        if ($CheckBox2.Checked){
            $CheckBox2_2.Checked=$True
            $CheckBox2_3_1.Checked=$True
            $CheckBox2_3_2.Checked=$True
            $CheckBox2_3_4.Checked=$True
            $CheckBox2_3_6.Checked=$True
            $CheckBox2_3_7.Checked=$True
            $CheckBox2_3_8.Checked=$True
            $CheckBox2_3_9.Checked=$True
            $CheckBox2_3_10.Checked=$True
            $CheckBox2_3_11.Checked=$True
            $CheckBox2_3_15.Checked=$True
            $CheckBox2_3_17.Checked=$True
    
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox2_2.Checked=$False
            $CheckBox2_3_1.Checked=$False
            $CheckBox2_3_2.Checked=$False
            $CheckBox2_3_4.Checked=$False
            $CheckBox2_3_6.Checked=$False
            $CheckBox2_3_7.Checked=$False
            $CheckBox2_3_8.Checked=$False
            $CheckBox2_3_9.Checked=$False
            $CheckBox2_3_10.Checked=$False
            $CheckBox2_3_11.Checked=$False
            $CheckBox2_3_15.Checked=$False
            $CheckBox2_3_17.Checked=$False
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    $CheckBox2_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_2.Location = New-Object System.Drawing.Size(50,295) 
    $CheckBox2_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_2.Text = "2.2 User Rights Assignment"
    $CheckBox2_2.AutoSize=$True
    $CheckBox2_2.Visible=$False
    $main_form.Controls.Add($CheckBox2_2)
    $CheckBox2_2.Add_Click({
        if(($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) -and ($CheckBox2_3_4.Checked) `
        -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_1.Location = New-Object System.Drawing.Size(525,295) 
    $CheckBox2_3_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_1.Text = "2.3.1 Accounts"
    $CheckBox2_3_1.AutoSize=$True
    $CheckBox2_3_1.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_1)
    $CheckBox2_3_1.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_2.Checked) -and ($CheckBox2_3_4.Checked) `
        -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_2.Location = New-Object System.Drawing.Size(925,295) 
    $CheckBox2_3_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_2.Text = "2.3.2 Audit"
    $CheckBox2_3_2.AutoSize=$True
    $CheckBox2_3_2.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_2)
    $CheckBox2_3_2.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_4.Checked) `
        -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_4.Location = New-Object System.Drawing.Size(1355,295) #850
    $CheckBox2_3_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_4.Text = "2.3.4 Devices"
    $CheckBox2_3_4.AutoSize=$True
    $CheckBox2_3_4.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_4)
    $CheckBox2_3_4.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_6 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_6.Location = New-Object System.Drawing.Size(50,325) 
    $CheckBox2_3_6.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_6.Text = "2.3.6 Domain member"
    $CheckBox2_3_6.AutoSize=$True
    $CheckBox2_3_6.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_6)
    $CheckBox2_3_6.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_6.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_7 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_7.Location = New-Object System.Drawing.Size(525,325) 
    $CheckBox2_3_7.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_7.Text = "2.3.7 Interactive logon"
    $CheckBox2_3_7.AutoSize=$True
    $CheckBox2_3_7.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_7)
    $CheckBox2_3_7.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_8.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_7.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_8 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_8.Location = New-Object System.Drawing.Size(925,325) 
    $CheckBox2_3_8.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_8.Text = "2.3.8 Microsoft Network Client"
    $CheckBox2_3_8.AutoSize=$True
    $CheckBox2_3_8.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_8)
    $CheckBox2_3_8.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_9.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_8.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_9 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_9.Location = New-Object System.Drawing.Size(1355,325) 
    $CheckBox2_3_9.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_9.Text = "2.3.9 Microsoft Network Server"
    $CheckBox2_3_9.AutoSize=$True
    $CheckBox2_3_9.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_9)
    $CheckBox2_3_9.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) `
        -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_9.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_10 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_10.Location = New-Object System.Drawing.Size(50,355) 
    $CheckBox2_3_10.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_10.Text = "2.3.10 Network access"
    $CheckBox2_3_10.AutoSize=$True
    $CheckBox2_3_10.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_10)
    $CheckBox2_3_10.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) `
        -and ($CheckBox2_3_9.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_10.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_11 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_11.Location = New-Object System.Drawing.Size(525,355) 
    $CheckBox2_3_11.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_11.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_11.Text = "2.3.11 Network security"
    $CheckBox2_3_11.AutoSize=$True
    $CheckBox2_3_11.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_11)
    $CheckBox2_3_11.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) `
        -and ($CheckBox2_3_9.Checked) -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_15.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_11.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_15 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_15.Location = New-Object System.Drawing.Size(925,355) 
    $CheckBox2_3_15.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_15.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_15.Text = "2.3.15 System objects"
    $CheckBox2_3_15.AutoSize=$True
    $CheckBox2_3_15.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_15)
    $CheckBox2_3_15.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) `
        -and ($CheckBox2_3_9.Checked) -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_17.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_15.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    $CheckBox2_3_17 = New-Object System.Windows.Forms.CheckBox
    $CheckBox2_3_17.Location = New-Object System.Drawing.Size(1355,355) 
    $CheckBox2_3_17.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox2_3_17.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox2_3_17.Text = "2.3.17 User Account Control"
    $CheckBox2_3_17.AutoSize=$True
    $CheckBox2_3_17.Visible=$False
    $main_form.Controls.Add($CheckBox2_3_17)
    $CheckBox2_3_17.Add_Click({
        if(($CheckBox2_2.Checked) -and ($CheckBox2_3_1.Checked) -and ($CheckBox2_3_2.Checked) `
        -and ($CheckBox2_3_4.Checked) -and ($CheckBox2_3_6.Checked) -and ($CheckBox2_3_7.Checked) -and ($CheckBox2_3_8.Checked) `
        -and ($CheckBox2_3_9.Checked) -and ($CheckBox2_3_10.Checked) -and ($CheckBox2_3_11.Checked) -and ($CheckBox2_3_15.Checked)){
            $CheckBox2.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox2_3_17.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox2.Checked=$False
        }
    
    })
    
    
    ### Check box Section 5
    $CheckBox5 = New-Object System.Windows.Forms.CheckBox
    $CheckBox5.Location = New-Object System.Drawing.Size(30,385) 
    $CheckBox5.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox5.Text = "Section 5"
    $CheckBox5.AutoSize=$True
    $CheckBox5.Visible=$False
    $main_form.Controls.Add($CheckBox5)
    
    
    ### Check box Section 9
    $CheckBox9 = New-Object System.Windows.Forms.CheckBox
    $CheckBox9.Location = New-Object System.Drawing.Size(30,415) 
    $CheckBox9.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox9.Text = "Section 9"
    $CheckBox9.AutoSize=$True
    $CheckBox9.Visible=$False
    $main_form.Controls.Add($CheckBox9)
    $CheckBox9.Add_Click({
        if ($CheckBox9.Checked){
            $CheckBox9_1.Checked=$True
            $CheckBox9_2.Checked=$True
            $CheckBox9_3.Checked=$True
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox9_1.Checked=$False
            $CheckBox9_2.Checked=$False
            $CheckBox9_3.Checked=$False
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    $CheckBox9_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox9_1.Location = New-Object System.Drawing.Size(50,445) 
    $CheckBox9_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox9_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox9_1.Text = "9.1 Domain Profile"
    $CheckBox9_1.AutoSize=$True
    $CheckBox9_1.Visible=$False
    $main_form.Controls.Add($CheckBox9_1)
    $CheckBox9_1.Add_Click({
        if(($CheckBox9_2.Checked) -and ($CheckBox9_3.Checked)){
            $CheckBox9.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox9_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox9.Checked=$False
        }
    
    })
    
    $CheckBox9_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox9_2.Location = New-Object System.Drawing.Size(525,445) 
    $CheckBox9_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox9_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox9_2.Text = "9.2 Private Profile"
    $CheckBox9_2.AutoSize=$True
    $CheckBox9_2.Visible=$False
    $main_form.Controls.Add($CheckBox9_2)
    $CheckBox9_2.Add_Click({
        if(($CheckBox9_1.Checked) -and ($CheckBox9_3.Checked)){
            $CheckBox9.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox9_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox9.Checked=$False
        }
    
    })
    
    $CheckBox9_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox9_3.Location = New-Object System.Drawing.Size(925,445) 
    $CheckBox9_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox9_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox9_3.Text = "9.3 Public Profile"
    $CheckBox9_3.AutoSize=$True
    $CheckBox9_3.Visible=$False
    $main_form.Controls.Add($CheckBox9_3)
    $CheckBox9_3.Add_Click({
        if(($CheckBox9_1.Checked) -and ($CheckBox9_2.Checked)){
            $CheckBox9.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox9_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox9.Checked=$False
        }
    
    })
    
    
    ### Check box Section 17
    $CheckBox17 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17.Location = New-Object System.Drawing.Size(30,475) 
    $CheckBox17.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17.Text = "Section 17"
    $CheckBox17.AutoSize=$True
    $CheckBox17.Visible=$False
    $main_form.Controls.Add($CheckBox17)
    $CheckBox17.Add_Click({
        if ($CheckBox17.Checked){
            $CheckBox17_1.Checked=$True
            $CheckBox17_2.Checked=$True
            $CheckBox17_3.Checked=$True
            $CheckBox17_5.Checked=$True
            $CheckBox17_6.Checked=$True
            $CheckBox17_7.Checked=$True
            $CheckBox17_8.Checked=$True
            $CheckBox17_9.Checked=$True
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox17_1.Checked=$False
            $CheckBox17_2.Checked=$False
            $CheckBox17_3.Checked=$False
            $CheckBox17_5.Checked=$False
            $CheckBox17_6.Checked=$False
            $CheckBox17_7.Checked=$False
            $CheckBox17_8.Checked=$False
            $CheckBox17_9.Checked=$False
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    $CheckBox17_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_1.Location = New-Object System.Drawing.Size(50,505) 
    $CheckBox17_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_1.Text = "17.1 Account Logon"
    $CheckBox17_1.AutoSize=$True
    $CheckBox17_1.Visible=$False
    $main_form.Controls.Add($CheckBox17_1)
    $CheckBox17_1.Add_Click({
        if(($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) -and ($CheckBox17_5.Checked) `
        -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_2.Location = New-Object System.Drawing.Size(525,505) 
    $CheckBox17_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_2.Text = "17.2 Account Management"
    $CheckBox17_2.AutoSize=$True
    $CheckBox17_2.Visible=$False
    $main_form.Controls.Add($CheckBox17_2)
    $CheckBox17_2.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_3.Checked) -and ($CheckBox17_5.Checked) `
        -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_3.Location = New-Object System.Drawing.Size(925,505) 
    $CheckBox17_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_3.Text = "17.3 Detailed Tracking"
    $CheckBox17_3.AutoSize=$True
    $CheckBox17_3.Visible=$False
    $main_form.Controls.Add($CheckBox17_3)
    $CheckBox17_3.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_5.Checked) `
        -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_5 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_5.Location = New-Object System.Drawing.Size(925,505) 
    $CheckBox17_5.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_5.Text = "17.5 Logon/Logoff"
    $CheckBox17_5.AutoSize=$True
    $CheckBox17_5.Visible=$False
    $main_form.Controls.Add($CheckBox17_5)
    $CheckBox17_5.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) `
        -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_5.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_6 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_6.Location = New-Object System.Drawing.Size(50,535) 
    $CheckBox17_6.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_6.Text = "17.6 Object Access"
    $CheckBox17_6.AutoSize=$True
    $CheckBox17_6.Visible=$False
    $main_form.Controls.Add($CheckBox17_6)
    $CheckBox17_6.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) `
        -and ($CheckBox17_5.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_6.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_7 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_7.Location = New-Object System.Drawing.Size(525,535) 
    $CheckBox17_7.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_7.Text = "17.7 Policy Change"
    $CheckBox17_7.AutoSize=$True
    $CheckBox17_7.Visible=$False
    $main_form.Controls.Add($CheckBox17_7)
    $CheckBox17_7.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) `
        -and ($CheckBox17_5.Checked) -and ($CheckBox17_6.Checked) -and ($CheckBox17_8.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_7.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_8 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_8.Location = New-Object System.Drawing.Size(925,535) 
    $CheckBox17_8.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_8.Text = "17.8 Privilege Use"
    $CheckBox17_8.AutoSize=$True
    $CheckBox17_8.Visible=$False
    $main_form.Controls.Add($CheckBox17_8)
    $CheckBox17_8.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) `
        -and ($CheckBox17_5.Checked) -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_9.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_8.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    $CheckBox17_9 = New-Object System.Windows.Forms.CheckBox
    $CheckBox17_9.Location = New-Object System.Drawing.Size(925,535) 
    $CheckBox17_9.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox17_9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox17_9.Text = "17.9 System"
    $CheckBox17_9.AutoSize=$True
    $CheckBox17_9.Visible=$False
    $main_form.Controls.Add($CheckBox17_9)
    $CheckBox17_9.Add_Click({
        if(($CheckBox17_1.Checked) -and ($CheckBox17_2.Checked) -and ($CheckBox17_3.Checked) `
        -and ($CheckBox17_5.Checked) -and ($CheckBox17_6.Checked) -and ($CheckBox17_7.Checked) -and ($CheckBox17_8.Checked)){
            $CheckBox17.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox17_9.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox17.Checked=$False
        }
    
    })
    
    
    ### Check box Section 18
    $CheckBox18 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18.Location = New-Object System.Drawing.Size(30,565) 
    $CheckBox18.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18.Text = "Section 18"
    $CheckBox18.AutoSize=$True
    $CheckBox18.Visible=$False
    $main_form.Controls.Add($CheckBox18)
    $CheckBox18.Add_Click({
        if ($CheckBox18.Checked){
            $CheckBox18_1_1.checked=$True
            $CheckBox18_1_2.checked=$True
            $CheckBox18_2.checked=$True
            $CheckBox18_3.checked=$True
            $CheckBox18_4.checked=$True
            $CheckBox18_5_4.checked=$True
            $CheckBox18_5_8.checked=$True
            $CheckBox18_5_11.checked=$True
            $CheckBox18_5_14.checked=$True
            $CheckBox18_5_21.checked=$True
            $CheckBox18_5_23_2.checked=$True
            $CheckBox18_6.checked=$True
            $CheckBox18_8_3.checked=$True
            $CheckBox18_8_4.checked=$True
            $CheckBox18_8_7.checked=$True
            $CheckBox18_8_14.checked=$True
            $CheckBox18_8_21.checked=$True
            $CheckBox18_8_22_1.checked=$True
            $CheckBox18_8_28.checked=$True
            $CheckBox18_8_34_6.checked=$True
            $CheckBox18_8_36.checked=$True
            $CheckBox18_8_37.checked=$True
            $CheckBox18_9_4.checked=$True
            $CheckBox18_9_5.checked=$True
            $CheckBox18_9_6.checked=$True
            $CheckBox18_9_8.checked=$True
            $CheckBox18_9_10_1.checked=$True
            $CheckBox18_9_14.checked=$True
            $CheckBox18_9_15.checked=$True
            $CheckBox18_9_16.checked=$True
            $CheckBox18_9_17.checked=$True
            $CheckBox18_9_18.checked=$True
            $CheckBox18_9_27_1.checked=$True
            $CheckBox18_9_27_2.checked=$True
            $CheckBox18_9_27_3.checked=$True
            $CheckBox18_9_27_4.checked=$True
            $CheckBox18_9_31.checked=$True
            $CheckBox18_9_36.checked=$True
            $CheckBox18_9_46.checked=$True
            $CheckBox18_9_47_4.checked=$True
            $CheckBox18_9_47_5_1.checked=$True
            $CheckBox18_9_47_5_3.checked=$True
            $CheckBox18_9_47_9.checked=$True
            $CheckBox18_9_47_12.checked=$True
            $CheckBox18_9_47_14.checked=$True
            $CheckBox18_9_58.checked=$True
            $CheckBox18_9_65_2.checked=$True
            $CheckBox18_9_65_3_3.checked=$True
            $CheckBox18_9_65_3_9.checked=$True
            $CheckBox18_9_65_3_11.checked=$True
            $CheckBox18_9_66.checked=$True
            $CheckBox18_9_67.checked=$True
            $CheckBox18_9_75.checked=$True
            $CheckBox18_9_81.checked=$True
            $CheckBox18_9_85_1.checked=$True
            $CheckBox18_9_85_2.checked=$True
            $CheckBox18_9_87.checked=$True
            $CheckBox18_9_89.checked=$True
            $CheckBox18_9_90.checked=$True
            $CheckBox18_9_91.checked=$True
            $CheckBox18_9_100.checked=$True
            $CheckBox18_9_102_1.checked=$True
            $CheckBox18_9_102_2.checked=$True
            $CheckBox18_9_104.checked=$True
            $CheckBox18_9_105_2.checked=$True
            $CheckBox18_9_108_1.checked=$True
            $CheckBox18_9_108_2.checked=$True
            $CheckBox18_9_108_4.checked=$True
    
            
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox18_1_1.checked=$False
            $CheckBox18_1_2.checked=$False
            $CheckBox18_2.checked=$False
            $CheckBox18_3.checked=$False
            $CheckBox18_4.checked=$False
            $CheckBox18_5_4.checked=$False
            $CheckBox18_5_8.checked=$False
            $CheckBox18_5_11.checked=$False
            $CheckBox18_5_14.checked=$False
            $CheckBox18_5_21.checked=$False
            $CheckBox18_5_23_2.checked=$False
            $CheckBox18_6.checked=$False
            $CheckBox18_8_3.checked=$False
            $CheckBox18_8_4.checked=$False
            $CheckBox18_8_7.checked=$False
            $CheckBox18_8_14.checked=$False
            $CheckBox18_8_21.checked=$False
            $CheckBox18_8_22_1.checked=$False
            $CheckBox18_8_28.checked=$False
            $CheckBox18_8_34_6.checked=$False
            $CheckBox18_8_36.checked=$False
            $CheckBox18_8_37.checked=$False
            $CheckBox18_9_4.checked=$False
            $CheckBox18_9_5.checked=$False
            $CheckBox18_9_6.checked=$False
            $CheckBox18_9_8.checked=$False
            $CheckBox18_9_10_1.checked=$False
            $CheckBox18_9_14.checked=$False
            $CheckBox18_9_15.checked=$False
            $CheckBox18_9_16.checked=$False
            $CheckBox18_9_17.checked=$False
            $CheckBox18_9_18.checked=$False
            $CheckBox18_9_27_1.checked=$False
            $CheckBox18_9_27_2.checked=$False
            $CheckBox18_9_27_3.checked=$False
            $CheckBox18_9_27_4.checked=$False
            $CheckBox18_9_31.checked=$False
            $CheckBox18_9_36.checked=$False
            $CheckBox18_9_46.checked=$False
            $CheckBox18_9_47_4.checked=$False
            $CheckBox18_9_47_5_1.checked=$False
            $CheckBox18_9_47_5_3.checked=$False
            $CheckBox18_9_47_9.checked=$False
            $CheckBox18_9_47_12.checked=$False
            $CheckBox18_9_47_14.checked=$False
            $CheckBox18_9_58.checked=$False
            $CheckBox18_9_65_2.checked=$False
            $CheckBox18_9_65_3_3.checked=$False
            $CheckBox18_9_65_3_9.checked=$False
            $CheckBox18_9_65_3_11.checked=$False
            $CheckBox18_9_66.checked=$False
            $CheckBox18_9_67.checked=$False
            $CheckBox18_9_75.checked=$False
            $CheckBox18_9_81.checked=$False
            $CheckBox18_9_85_1.checked=$False
            $CheckBox18_9_85_2.checked=$False
            $CheckBox18_9_87.checked=$False
            $CheckBox18_9_89.checked=$False
            $CheckBox18_9_90.checked=$False
            $CheckBox18_9_91.checked=$False
            $CheckBox18_9_100.checked=$False
            $CheckBox18_9_102_1.checked=$False
            $CheckBox18_9_102_2.checked=$False
            $CheckBox18_9_104.checked=$False
            $CheckBox18_9_105_2.checked=$False
            $CheckBox18_9_108_1.checked=$False
            $CheckBox18_9_108_2.checked=$False
            $CheckBox18_9_108_4.checked=$False
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    $CheckBox18_1_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_1_1.Location = New-Object System.Drawing.Size(50,595) 
    $CheckBox18_1_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_1_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_1_1.Text = "18.1.1 Personalization"
    $CheckBox18_1_1.AutoSize=$True
    $CheckBox18_1_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_1_1)
    $CheckBox18_1_1.Add_Click({
        if(($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) -and ($CheckBox18_5_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_1_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_1_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_1_2.Location = New-Object System.Drawing.Size(525,595) 
    $CheckBox18_1_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_1_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_1_2.Text = "18.1.2 Regional and Language Options"
    $CheckBox18_1_2.AutoSize=$True
    $CheckBox18_1_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_1_2)
    $CheckBox18_1_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) -and ($CheckBox18_5_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_1_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_2.Location = New-Object System.Drawing.Size(925,595) 
    $CheckBox18_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_2.Text = "18.2 LAPS"
    $CheckBox18_2.AutoSize=$True
    $CheckBox18_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_2)
    $CheckBox18_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) -and ($CheckBox18_5_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_3.Location = New-Object System.Drawing.Size(1355,595) 
    $CheckBox18_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_3.Text = "18.3 MS Security Guide"
    $CheckBox18_3.AutoSize=$True
    $CheckBox18_3.Visible=$False
    $main_form.Controls.Add($CheckBox18_3)
    $CheckBox18_3.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_4.Checked) -and ($CheckBox18_5_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_4.Location = New-Object System.Drawing.Size(50,625) 
    $CheckBox18_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_4.Text = "18.4 MSS (Legacy)"
    $CheckBox18_4.AutoSize=$True
    $CheckBox18_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_4)
    $CheckBox18_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_5_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_4.Location = New-Object System.Drawing.Size(525,625) 
    $CheckBox18_5_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_4.Text = "18.5.4 DNS Client"
    $CheckBox18_5_4.AutoSize=$True
    $CheckBox18_5_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_4)
    $CheckBox18_5_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_8 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_8.Location = New-Object System.Drawing.Size(925,625) 
    $CheckBox18_5_8.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_8.Text = "18.5.8 Lanman Workstation"
    $CheckBox18_5_8.AutoSize=$True
    $CheckBox18_5_8.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_8)
    $CheckBox18_5_8.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_8.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_11 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_11.Location = New-Object System.Drawing.Size(1355,625) 
    $CheckBox18_5_11.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_11.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_11.Text = "18.5.11 Network Connections"
    $CheckBox18_5_11.AutoSize=$True
    $CheckBox18_5_11.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_11)
    $CheckBox18_5_11.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_11.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_14 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_14.Location = New-Object System.Drawing.Size(50,655) 
    $CheckBox18_5_14.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_14.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_14.Text = "18.5.14 Network Provider"
    $CheckBox18_5_14.AutoSize=$True
    $CheckBox18_5_14.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_14)
    $CheckBox18_5_14.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_21.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_14.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_21 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_21.Location = New-Object System.Drawing.Size(525,655) 
    $CheckBox18_5_21.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_21.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_21.Text = "18.5.21 Windows Connection Manager"
    $CheckBox18_5_21.AutoSize=$True
    $CheckBox18_5_21.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_21)
    $CheckBox18_5_21.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_23_2.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_21.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_5_23_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_5_23_2.Location = New-Object System.Drawing.Size(925,655) 
    $CheckBox18_5_23_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_5_23_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_5_23_2.Text = "18.5.23.2 WLAN Settings"
    $CheckBox18_5_23_2.AutoSize=$True
    $CheckBox18_5_23_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_5_23_2)
    $CheckBox18_5_23_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_5_23_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_6 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_6.Location = New-Object System.Drawing.Size(1355,655) 
    $CheckBox18_6.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_6.Text = "18.6 Printers"
    $CheckBox18_6.AutoSize=$True
    $CheckBox18_6.Visible=$False
    $main_form.Controls.Add($CheckBox18_6)
    $CheckBox18_6.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_6.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_3.Location = New-Object System.Drawing.Size(50,685) 
    $CheckBox18_8_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_3.Text = "18.8.3 Audit Process Creation"
    $CheckBox18_8_3.AutoSize=$True
    $CheckBox18_8_3.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_3)
    $CheckBox18_8_3.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_4.Location = New-Object System.Drawing.Size(525,685) 
    $CheckBox18_8_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_4.Text = "18.8.4 Credentials Delegation"
    $CheckBox18_8_4.AutoSize=$True
    $CheckBox18_8_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_4)
    $CheckBox18_8_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_7.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_7 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_7.Location = New-Object System.Drawing.Size(925,685) 
    $CheckBox18_8_7.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_7.Text = "18.8.7 Device Installation"
    $CheckBox18_8_7.AutoSize=$True
    $CheckBox18_8_7.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_7)
    $CheckBox18_8_7.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_14.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_7.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_14 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_14.Location = New-Object System.Drawing.Size(1355,685) 
    $CheckBox18_8_14.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_14.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_14.Text = "18.8.14 Early Launch Antimalware"
    $CheckBox18_8_14.AutoSize=$True
    $CheckBox18_8_14.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_14)
    $CheckBox18_8_14.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_14.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_21 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_21.Location = New-Object System.Drawing.Size(50,715) 
    $CheckBox18_8_21.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_21.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_21.Text = "18.8.21 Group Policy"
    $CheckBox18_8_21.AutoSize=$True
    $CheckBox18_8_21.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_21)
    $CheckBox18_8_21.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_21.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_22_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_22_1.Location = New-Object System.Drawing.Size(525,715) 
    $CheckBox18_8_22_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_22_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_22_1.Text = "18.8.22.1 Internet Communication settings"
    $CheckBox18_8_22_1.AutoSize=$True
    $CheckBox18_8_22_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_22_1)
    $CheckBox18_8_22_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_22_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_28 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_28.Location = New-Object System.Drawing.Size(925,715) 
    $CheckBox18_8_28.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_28.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_28.Text = "18.8.28 Logon"
    $CheckBox18_8_28.AutoSize=$True
    $CheckBox18_8_28.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_28)
    $CheckBox18_8_28.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_34_6.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_28.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_34_6 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_34_6.Location = New-Object System.Drawing.Size(1355,715) 
    $CheckBox18_8_34_6.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_34_6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_34_6.Text = "18.8.34.6 Sleep Settings"
    $CheckBox18_8_34_6.AutoSize=$True
    $CheckBox18_8_34_6.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_34_6)
    $CheckBox18_8_34_6.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_36.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_34_6.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_36 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_36.Location = New-Object System.Drawing.Size(50,745) 
    $CheckBox18_8_36.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_36.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_36.Text = "18.8.36 Remote Assistance"
    $CheckBox18_8_36.AutoSize=$True
    $CheckBox18_8_36.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_36)
    $CheckBox18_8_36.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_36.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_8_37 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_8_37.Location = New-Object System.Drawing.Size(525,745) 
    $CheckBox18_8_37.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_8_37.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_8_37.Text = "18.8.37 Remote Procedure Call"
    $CheckBox18_8_37.AutoSize=$True
    $CheckBox18_8_37.Visible=$False
    $main_form.Controls.Add($CheckBox18_8_37)
    $CheckBox18_8_37.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_8_37.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_4.Location = New-Object System.Drawing.Size(925,745) 
    $CheckBox18_9_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_4.Text = "18.9.4 App Package Deployment"
    $CheckBox18_9_4.AutoSize=$True
    $CheckBox18_9_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_4)
    $CheckBox18_9_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_5 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_5.Location = New-Object System.Drawing.Size(1355,745) 
    $CheckBox18_9_5.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_5.Text = "18.9.5 App Privacy"
    $CheckBox18_9_5.AutoSize=$True
    $CheckBox18_9_5.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_5)
    $CheckBox18_9_5.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_6.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_5.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_6 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_6.Location = New-Object System.Drawing.Size(50,775) 
    $CheckBox18_9_6.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_6.Text = "18.9.6 App runtime"
    $CheckBox18_9_6.AutoSize=$True
    $CheckBox18_9_6.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_6)
    $CheckBox18_9_6.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_8.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_6.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_8 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_8.Location = New-Object System.Drawing.Size(525,775) 
    $CheckBox18_9_8.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_8.Text = "18.9.8 AutoPlay Policies"
    $CheckBox18_9_8.AutoSize=$True
    $CheckBox18_9_8.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_8)
    $CheckBox18_9_8.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_8.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_10_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_10_1.Location = New-Object System.Drawing.Size(925,775) 
    $CheckBox18_9_10_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_10_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_10_1.Text = "18.9.10.1 Facial Features"
    $CheckBox18_9_10_1.AutoSize=$True
    $CheckBox18_9_10_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_10_1)
    $CheckBox18_9_10_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_10_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_14 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_14.Location = New-Object System.Drawing.Size(1355,775) 
    $CheckBox18_9_14.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_14.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_14.Text = "18.9.14 Cloud Content"
    $CheckBox18_9_14.AutoSize=$True
    $CheckBox18_9_14.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_14)
    $CheckBox18_9_14.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_14.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_15 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_15.Location = New-Object System.Drawing.Size(50,805) 
    $CheckBox18_9_15.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_15.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_15.Text = "18.9.15 Connect"
    $CheckBox18_9_15.AutoSize=$True
    $CheckBox18_9_15.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_15)
    $CheckBox18_9_15.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_16.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_15.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_16 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_16.Location = New-Object System.Drawing.Size(525,805) 
    $CheckBox18_9_16.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_16.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_16.Text = "18.9.16 Credential User Interface"
    $CheckBox18_9_16.AutoSize=$True
    $CheckBox18_9_16.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_16)
    $CheckBox18_9_16.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_17.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_16.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_17 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_17.Location = New-Object System.Drawing.Size(925,805) 
    $CheckBox18_9_17.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_17.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_17.Text = "18.9.17 Data Collection and Preview Builds"
    $CheckBox18_9_17.AutoSize=$True
    $CheckBox18_9_17.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_17)
    $CheckBox18_9_17.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_17.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_18 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_18.Location = New-Object System.Drawing.Size(1355,805) 
    $CheckBox18_9_18.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_18.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_18.Text = "18.9.18 Delivery Optimization"
    $CheckBox18_9_18.AutoSize=$True
    $CheckBox18_9_18.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_18)
    $CheckBox18_9_18.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_18.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_27_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_27_1.Location = New-Object System.Drawing.Size(50,835) 
    $CheckBox18_9_27_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_27_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_27_1.Text = "18.9.27.1 Application"
    $CheckBox18_9_27_1.AutoSize=$True
    $CheckBox18_9_27_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_27_1)
    $CheckBox18_9_27_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_27_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_27_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_27_2.Location = New-Object System.Drawing.Size(525,835) 
    $CheckBox18_9_27_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_27_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_27_2.Text = "18.9.27.2 Security"
    $CheckBox18_9_27_2.AutoSize=$True
    $CheckBox18_9_27_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_27_2)
    $CheckBox18_9_27_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_3.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_27_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_27_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_27_3.Location = New-Object System.Drawing.Size(925,835) 
    $CheckBox18_9_27_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_27_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_27_3.Text = "18.9.27.3 Setup"
    $CheckBox18_9_27_3.AutoSize=$True
    $CheckBox18_9_27_3.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_27_3)
    $CheckBox18_9_27_3.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_4.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_27_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_27_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_27_4.Location = New-Object System.Drawing.Size(1355,835) 
    $CheckBox18_9_27_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_27_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_27_4.Text = "18.9.27.4 System"
    $CheckBox18_9_27_4.AutoSize=$True
    $CheckBox18_9_27_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_27_4)
    $CheckBox18_9_27_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_27_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_31 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_31.Location = New-Object System.Drawing.Size(50,865) 
    $CheckBox18_9_31.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_31.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_31.Text = "18.9.31 File Explorer (formerly Windows Explorer)"
    $CheckBox18_9_31.AutoSize=$True
    $CheckBox18_9_31.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_31)
    $CheckBox18_9_31.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_31.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_36 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_36.Location = New-Object System.Drawing.Size(525,865) 
    $CheckBox18_9_36.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_36.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_36.Text = "18.9.36 HomeGroup"
    $CheckBox18_9_36.AutoSize=$True
    $CheckBox18_9_36.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_36)
    $CheckBox18_9_36.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_36.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_46 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_46.Location = New-Object System.Drawing.Size(925,865) 
    $CheckBox18_9_46.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_46.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_46.Text = "18.9.46 Microsoft account"
    $CheckBox18_9_46.AutoSize=$True
    $CheckBox18_9_46.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_46)
    $CheckBox18_9_46.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_47_4.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_46.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_4.Location = New-Object System.Drawing.Size(1355,865) 
    $CheckBox18_9_47_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_4.Text = "18.9.47.4 MAPS"
    $CheckBox18_9_47_4.AutoSize=$True
    $CheckBox18_9_47_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_4)
    $CheckBox18_9_47_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_5_1.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_5_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_5_1.Location = New-Object System.Drawing.Size(50,895) 
    $CheckBox18_9_47_5_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_5_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_5_1.Text = "18.9.47.5.1 Attack Surface Reduction"
    $CheckBox18_9_47_5_1.AutoSize=$True
    $CheckBox18_9_47_5_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_5_1)
    $CheckBox18_9_47_5_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_5_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_5_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_5_3.Location = New-Object System.Drawing.Size(525,895) 
    $CheckBox18_9_47_5_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_5_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_5_3.Text = "18.9.47.5.3 Network Protection"
    $CheckBox18_9_47_5_3.AutoSize=$True
    $CheckBox18_9_47_5_3.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_5_3)
    $CheckBox18_9_47_5_3.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_5_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_9 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_9.Location = New-Object System.Drawing.Size(925,895) 
    $CheckBox18_9_47_9.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_9.Text = "18.9.47.9 Real-time Protection"
    $CheckBox18_9_47_9.AutoSize=$True
    $CheckBox18_9_47_9.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_9)
    $CheckBox18_9_47_9.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_9.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_12 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_12.Location = New-Object System.Drawing.Size(1355,895) 
    $CheckBox18_9_47_12.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_12.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_12.Text = "18.9.47.12 Scan"
    $CheckBox18_9_47_12.AutoSize=$True
    $CheckBox18_9_47_12.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_12)
    $CheckBox18_9_47_12.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_14.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_12.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_47_14 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_47_14.Location = New-Object System.Drawing.Size(50,925) 
    $CheckBox18_9_47_14.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_47_14.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_47_14.Text = "18.9.47.14 Threats"
    $CheckBox18_9_47_14.AutoSize=$True
    $CheckBox18_9_47_14.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_47_14)
    $CheckBox18_9_47_14.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_58.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_47_14.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_58 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_58.Location = New-Object System.Drawing.Size(525,925) 
    $CheckBox18_9_58.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_58.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_58.Text = "18.9.58 OneDrive (formerly SkyDrive)"
    $CheckBox18_9_58.AutoSize=$True
    $CheckBox18_9_58.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_58)
    $CheckBox18_9_58.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_58.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_65_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_65_2.Location = New-Object System.Drawing.Size(925,925) 
    $CheckBox18_9_65_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_65_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_65_2.Text = "18.9.65.2 Remote Desktop Connection Client"
    $CheckBox18_9_65_2.AutoSize=$True
    $CheckBox18_9_65_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_65_2)
    $CheckBox18_9_65_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_65_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_65_3_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_65_3_3.Location = New-Object System.Drawing.Size(1355,925) 
    $CheckBox18_9_65_3_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_65_3_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_65_3_3.Text = "18.9.65.3.3 Device and Resource Redirection"
    $CheckBox18_9_65_3_3.AutoSize=$True
    $CheckBox18_9_65_3_3.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_65_3_3)
    $CheckBox18_9_65_3_3.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_65_3_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_65_3_9 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_65_3_9.Location = New-Object System.Drawing.Size(50,955) 
    $CheckBox18_9_65_3_9.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_65_3_9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_65_3_9.Text = "18.9.65.3.9 Security"
    $CheckBox18_9_65_3_9.AutoSize=$True
    $CheckBox18_9_65_3_9.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_65_3_9)
    $CheckBox18_9_65_3_9.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_11.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_65_3_9.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_65_3_11 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_65_3_11.Location = New-Object System.Drawing.Size(525,955) 
    $CheckBox18_9_65_3_11.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_65_3_11.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_65_3_11.Text = "18.9.65.3.11 Temporary folders"
    $CheckBox18_9_65_3_11.AutoSize=$True
    $CheckBox18_9_65_3_11.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_65_3_11)
    $CheckBox18_9_65_3_11.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_66.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_65_3_11.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_66 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_66.Location = New-Object System.Drawing.Size(925,955) 
    $CheckBox18_9_66.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_66.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_66.Text = "18.9.66 RSS Feeds"
    $CheckBox18_9_66.AutoSize=$True
    $CheckBox18_9_66.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_66)
    $CheckBox18_9_66.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_66.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_67 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_67.Location = New-Object System.Drawing.Size(1355,955) 
    $CheckBox18_9_67.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_67.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_67.Text = "18.9.67 Search"
    $CheckBox18_9_67.AutoSize=$True
    $CheckBox18_9_67.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_67)
    $CheckBox18_9_67.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_67.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_75 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_75.Location = New-Object System.Drawing.Size(50,985) 
    $CheckBox18_9_75.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_75.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_75.Text = "18.9.75 Store"
    $CheckBox18_9_75.AutoSize=$True
    $CheckBox18_9_75.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_75)
    $CheckBox18_9_75.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_75.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_81 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_81.Location = New-Object System.Drawing.Size(525,985) 
    $CheckBox18_9_81.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_81.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_81.Text = "18.9.81 Widgets"
    $CheckBox18_9_81.AutoSize=$True
    $CheckBox18_9_81.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_81)
    $CheckBox18_9_81.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_85_1.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_81.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_85_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_85_1.Location = New-Object System.Drawing.Size(925,985) 
    $CheckBox18_9_85_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_85_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_85_1.Text = "18.9.85.1 Explorer"
    $CheckBox18_9_85_1.AutoSize=$True
    $CheckBox18_9_85_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_85_1)
    $CheckBox18_9_85_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_2.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_85_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_85_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_85_2.Location = New-Object System.Drawing.Size(1355,985) 
    $CheckBox18_9_85_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_85_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_85_2.Text = "18.9.85.2 Microsoft Edge"
    $CheckBox18_9_85_2.AutoSize=$True
    $CheckBox18_9_85_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_85_2)
    $CheckBox18_9_85_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_85_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_87 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_87.Location = New-Object System.Drawing.Size(50,1015) 
    $CheckBox18_9_87.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_87.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_87.Text = "18.9.87 Windows Game Recording and Broadcasting"
    $CheckBox18_9_87.AutoSize=$True
    $CheckBox18_9_87.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_87)
    $CheckBox18_9_87.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_87.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_89 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_89.Location = New-Object System.Drawing.Size(525,1015) 
    $CheckBox18_9_89.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_89.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_89.Text = "18.9.89 Windows Ink Workspace"
    $CheckBox18_9_89.AutoSize=$True
    $CheckBox18_9_89.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_89)
    $CheckBox18_9_89.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_89.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_90 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_90.Location = New-Object System.Drawing.Size(925,1015) 
    $CheckBox18_9_90.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_90.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_90.Text = "18.9.90 Windows Installer"
    $CheckBox18_9_90.AutoSize=$True
    $CheckBox18_9_90.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_90)
    $CheckBox18_9_90.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_91.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_90.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_91 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_91.Location = New-Object System.Drawing.Size(1355,1015) 
    $CheckBox18_9_91.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_91.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_91.Text = "18.9.91 Windows Logon Options"
    $CheckBox18_9_91.AutoSize=$True
    $CheckBox18_9_91.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_91)
    $CheckBox18_9_91.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_100.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_91.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_100 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_100.Location = New-Object System.Drawing.Size(50,1045) 
    $CheckBox18_9_100.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_100.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_100.Text = "18.9.100 Windows PowerShell"
    $CheckBox18_9_100.AutoSize=$True
    $CheckBox18_9_100.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_100)
    $CheckBox18_9_100.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_100.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_102_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_102_1.Location = New-Object System.Drawing.Size(525,1045) 
    $CheckBox18_9_102_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_102_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_102_1.Text = "18.9.102.1 WinRM Client"
    $CheckBox18_9_102_1.AutoSize=$True
    $CheckBox18_9_102_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_102_1)
    $CheckBox18_9_102_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_102_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_102_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_102_2.Location = New-Object System.Drawing.Size(925,1045) 
    $CheckBox18_9_102_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_102_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_102_2.Text = "18.9.102.2 WinRM Service"
    $CheckBox18_9_102_2.AutoSize=$True
    $CheckBox18_9_102_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_102_2)
    $CheckBox18_9_102_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_102_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_104 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_104.Location = New-Object System.Drawing.Size(1355,1045) 
    $CheckBox18_9_104.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_104.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_104.Text = "18.9.104 Windows Sandbox"
    $CheckBox18_9_104.AutoSize=$True
    $CheckBox18_9_104.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_104)
    $CheckBox18_9_104.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_105_2.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_104.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_105_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_105_2.Location = New-Object System.Drawing.Size(50,1075) 
    $CheckBox18_9_105_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_105_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_105_2.Text = "18.9.105.2 App and browser protection"
    $CheckBox18_9_105_2.AutoSize=$True
    $CheckBox18_9_105_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_105_2)
    $CheckBox18_9_105_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_108_1.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_105_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_108_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_108_1.Location = New-Object System.Drawing.Size(525,1075) 
    $CheckBox18_9_108_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_108_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_108_1.Text = "18.9.108.1 Legacy Policies"
    $CheckBox18_9_108_1.AutoSize=$True
    $CheckBox18_9_108_1.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_108_1)
    $CheckBox18_9_108_1.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) `
        -and ($CheckBox18_9_108_2.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_108_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_108_2 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_108_2.Location = New-Object System.Drawing.Size(925,1075) 
    $CheckBox18_9_108_2.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_108_2.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_108_2.Text = "18.9.108.2 Manage end user experience"
    $CheckBox18_9_108_2.AutoSize=$True
    $CheckBox18_9_108_2.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_108_2)
    $CheckBox18_9_108_2.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) `
        -and ($CheckBox18_9_108_1.Checked) -and ($CheckBox18_9_108_4.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_108_2.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    $CheckBox18_9_108_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox18_9_108_4.Location = New-Object System.Drawing.Size(1355,1075) 
    $CheckBox18_9_108_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox18_9_108_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox18_9_108_4.Text = "18.9.108.4 Manage updates offered from Windows Update"
    $CheckBox18_9_108_4.AutoSize=$True
    $CheckBox18_9_108_4.Visible=$False
    $main_form.Controls.Add($CheckBox18_9_108_4)
    $CheckBox18_9_108_4.Add_Click({
        if(($CheckBox18_1_1.Checked) -and ($CheckBox18_1_2.Checked) -and ($CheckBox18_2.Checked) -and ($CheckBox18_3.Checked) -and ($CheckBox18_4.Checked) `
        -and ($CheckBox18_5_4.Checked) -and ($CheckBox18_5_8.Checked) -and ($CheckBox18_5_11.Checked) -and ($CheckBox18_5_14.Checked) -and ($CheckBox18_5_21.Checked) `
        -and ($CheckBox18_5_23_2.Checked) -and ($CheckBox18_6.Checked) -and ($CheckBox18_8_3.Checked) -and ($CheckBox18_8_4.Checked) -and ($CheckBox18_8_7.Checked) `
        -and ($CheckBox18_8_14.Checked) -and ($CheckBox18_8_21.Checked) -and ($CheckBox18_8_22_1.Checked) -and ($CheckBox18_8_28.Checked) -and ($CheckBox18_8_34_6.Checked) `
        -and ($CheckBox18_8_36.Checked) -and ($CheckBox18_8_37.Checked) -and ($CheckBox18_9_4.Checked) -and ($CheckBox18_9_5.Checked) -and ($CheckBox18_9_6.Checked) `
        -and ($CheckBox18_9_8.Checked) -and ($CheckBox18_9_10_1.Checked) -and ($CheckBox18_9_14.Checked) -and ($CheckBox18_9_15.Checked) -and ($CheckBox18_9_16.Checked) `
        -and ($CheckBox18_9_17.Checked) -and ($CheckBox18_9_18.Checked) -and ($CheckBox18_9_27_1.Checked) -and ($CheckBox18_9_27_2.Checked) -and ($CheckBox18_9_27_3.Checked) `
        -and ($CheckBox18_9_27_4.Checked) -and ($CheckBox18_9_31.Checked) -and ($CheckBox18_9_36.Checked) -and ($CheckBox18_9_46.Checked) -and ($CheckBox18_9_47_4.Checked) `
        -and ($CheckBox18_9_47_5_1.Checked) -and ($CheckBox18_9_47_5_3.Checked) -and ($CheckBox18_9_47_9.Checked) -and ($CheckBox18_9_47_12.Checked) -and ($CheckBox18_9_47_14.Checked) `
        -and ($CheckBox18_9_58.Checked) -and ($CheckBox18_9_65_2.Checked) -and ($CheckBox18_9_65_3_3.Checked) -and ($CheckBox18_9_65_3_9.Checked) -and ($CheckBox18_9_65_3_11.Checked) `
        -and ($CheckBox18_9_66.Checked) -and ($CheckBox18_9_67.Checked) -and ($CheckBox18_9_75.Checked) -and ($CheckBox18_9_81.Checked) -and ($CheckBox18_9_85_1.Checked) `
        -and ($CheckBox18_9_85_2.Checked) -and ($CheckBox18_9_87.Checked) -and ($CheckBox18_9_89.Checked) -and ($CheckBox18_9_90.Checked) -and ($CheckBox18_9_91.Checked) `
        -and ($CheckBox18_9_100.Checked) -and ($CheckBox18_9_102_1.Checked) -and ($CheckBox18_9_102_2.Checked) -and ($CheckBox18_9_104.Checked) -and ($CheckBox18_9_105_2.Checked) `
        -and ($CheckBox18_9_108_1.Checked) -and ($CheckBox18_9_108_2.Checked)){
            $CheckBox18.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox18_9_108_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox18.Checked=$False
        }
    
    })
    
    
    
    
    
    ### Check box Section 19
    $CheckBox19 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19.Location = New-Object System.Drawing.Size(30,1105) 
    $CheckBox19.Size = New-Object System.Drawing.Size(140,43)
    $CheckBox19.Text = "Section 19"
    $CheckBox19.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19.AutoSize=$True
    $CheckBox19.Visible=$False
    $main_form.Controls.Add($CheckBox19)
    $CheckBox19.Add_Click({
        if ($CheckBox19.Checked){
            $CheckBox19_1_3.Checked=$True
            $CheckBox19_5_1.Checked=$True
            $CheckBox19_7_4.Checked=$True
            $CheckBox19_7_8.Checked=$True
            $CheckBox19_7_28.Checked=$True
            $CheckBox19_7_43.Checked=$True
            
        }
        else{
            $CheckAllBoxes.Checked=$False
            $CheckBox19_1_3.Checked=$False
            $CheckBox19_5_1.Checked=$False
            $CheckBox19_7_4.Checked=$False
            $CheckBox19_7_8.Checked=$False
            $CheckBox19_7_28.Checked=$False
            $CheckBox19_7_43.Checked=$False
            
        }
        if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
            $CheckAllBoxes.Checked=$True
        }
    })
    
    $CheckBox19_1_3 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_1_3.Location = New-Object System.Drawing.Size(50,1135) 
    $CheckBox19_1_3.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_1_3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_1_3.Text = "19.1.3 Personalization (formerly Desktop Themes)"
    $CheckBox19_1_3.AutoSize=$True
    $CheckBox19_1_3.Visible=$False
    $main_form.Controls.Add($CheckBox19_1_3)
    $CheckBox19_1_3.Add_Click({
        if(($CheckBox19_5_1.Checked) -and ($CheckBox19_7_4.Checked) -and ($CheckBox19_7_8.Checked) `
        -and ($CheckBox19_7_28.Checked) -and ($CheckBox19_7_43.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_1_3.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    $CheckBox19_5_1 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_5_1.Location = New-Object System.Drawing.Size(525,1135) 
    $CheckBox19_5_1.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_5_1.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_5_1.Text = "19.5.1 Notifications"
    $CheckBox19_5_1.AutoSize=$True
    $CheckBox19_5_1.Visible=$False
    $main_form.Controls.Add($CheckBox19_5_1)
    $CheckBox19_5_1.Add_Click({
        if(($CheckBox19_1_3.Checked) -and ($CheckBox19_7_4.Checked) -and ($CheckBox19_7_8.Checked) `
        -and ($CheckBox19_7_28.Checked) -and ($CheckBox19_7_43.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_5_1.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    $CheckBox19_7_4 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_7_4.Location = New-Object System.Drawing.Size(925,1135) 
    $CheckBox19_7_4.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_7_4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_7_4.Text = "19.7.4 Attachment Manager"
    $CheckBox19_7_4.AutoSize=$True
    $CheckBox19_7_4.Visible=$False
    $main_form.Controls.Add($CheckBox19_7_4)
    $CheckBox19_7_4.Add_Click({
        if(($CheckBox19_1_3.Checked) -and ($CheckBox19_5_1.Checked) -and ($CheckBox19_7_8.Checked) `
        -and ($CheckBox19_7_28.Checked) -and ($CheckBox19_7_43.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_7_4.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    $CheckBox19_7_8 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_7_8.Location = New-Object System.Drawing.Size(1355,1135) 
    $CheckBox19_7_8.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_7_8.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_7_8.Text = "19.7.8 Cloud Content"
    $CheckBox19_7_8.AutoSize=$True
    $CheckBox19_7_8.Visible=$False
    $main_form.Controls.Add($CheckBox19_7_8)
    $CheckBox19_7_8.Add_Click({
        if(($CheckBox19_1_3.Checked) -and ($CheckBox19_5_1.Checked) -and ($CheckBox19_7_4.Checked) `
        -and ($CheckBox19_7_28.Checked) -and ($CheckBox19_7_43.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_7_8.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    $CheckBox19_7_28 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_7_28.Location = New-Object System.Drawing.Size(50,1165) 
    $CheckBox19_7_28.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_7_28.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_7_28.Text = "19.7.28 Network Sharing"
    $CheckBox19_7_28.AutoSize=$True
    $CheckBox19_7_28.Visible=$False
    $main_form.Controls.Add($CheckBox19_7_28)
    $CheckBox19_7_28.Add_Click({
        if(($CheckBox19_1_3.Checked) -and ($CheckBox19_5_1.Checked) -and ($CheckBox19_7_4.Checked) `
        -and ($CheckBox19_7_8.Checked) -and ($CheckBox19_7_43.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_7_28.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    $CheckBox19_7_43 = New-Object System.Windows.Forms.CheckBox
    $CheckBox19_7_43.Location = New-Object System.Drawing.Size(525,1165)
    $CheckBox19_7_43.Size = New-Object System.Drawing.Size(120,23)
    $CheckBox19_7_43.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $CheckBox19_7_43.Text = "19.7.43 Windows Installer"
    $CheckBox19_7_43.AutoSize=$True
    $CheckBox19_7_43.Visible=$False
    $main_form.Controls.Add($CheckBox19_7_43)
    $CheckBox19_7_43.Add_Click({
        if(($CheckBox19_1_3.Checked) -and ($CheckBox19_5_1.Checked) -and ($CheckBox19_7_4.Checked) `
        -and ($CheckBox19_7_8.Checked) -and ($CheckBox19_7_28.Checked)){
            $CheckBox19.Checked=$True
            if(($CheckBox1.Checked) -and ($CheckBox2.Checked) -and ($CheckBox5.Checked) -and ($CheckBox9.Checked) -and ($CheckBox17.Checked) -and ($CheckBox18.Checked) -and ($CheckBox19.Checked)){
                $CheckAllBoxes.Checked=$True
            }
        }
        if(-Not ($CheckBox19_7_43.Checked)){
            $CheckAllBoxes.Checked=$False
            $CheckBox19.Checked=$False
        }
    
    })
    
    
    ### Select Button
    $SelectFileButton = New-Object System.Windows.Forms.Button
    $SelectFileButton.Location = New-Object System.Drawing.Size(850,690)
    $SelectFileButton.Size = New-Object System.Drawing.Size(125,45)
    $SelectFileButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $SelectFileButton.Text = "Select File"
    $SelectFileButton.Anchor = 'Bottom, Right'
    
    
    
    $main_form.Controls.Add($SelectFileButton)
    $SelectFileButton.Visible=$False
    ### On Button click
    $SelectFileButton.Add_Click({
        ##hereereer
        ###Set the colors
        $Global:HiglightPg4=@("1.1","1.2","2.2","2.3.1","2.3.2","2.3.4","2.3.6","2.3.7","2.3.8","2.3.9","2.3.10","2.3.11","2.3.15","2.3.17","5","9.1","9.2","9.3",
        "17.1","17.2","17.3","17.5","17.6","17.7","17.8","17.9","18.1.1","18.1.2","18.2","18.3","18.4","18.5.4","18.5.8","18.5.11","18.5.14","18.5.21","18.5.23.2",
        "18.6","18.8.3","18.8.4","18.8.7","18.8.14","18.8.21","18.8.22.1", "18.8.28", "18.8.34.6","18.8.36","18.8.37","18.9.4","18.9.5","18.9.6","18.9.8","18.9.10.1",
        "18.9.14","18.9.15", "18.9.16", "18.9.17", "18.9.18", "18.9.27.1", "18.9.27.2","18.9.27.3","18.9.27.4","18.9.31","18.9.36","18.9.46","18.9.47.4","18.9.47.5.1", 
        "18.9.47.5.3", "18.9.47.9", "18.9.47.12", "18.9.47.14","18.9.58","18.9.65.2","18.9.65.3.3","18.9.65.3.9","18.9.65.3.11","18.9.66","18.9.67","18.9.75","18.9.81", 
        "18.9.85.1","18.9.85.2","18.9.87","18.9.89","18.9.90","18.9.91","18.9.100","18.9.102.1","18.9.102.2","18.9.104","18.9.105.2","18.9.108.1","18.9.108.2","18.9.108.4", 
        "19.1.3", "19.5.1", "19.7.4", "19.7.8", "19.7.28", "19.7.43")
        for ($i=0;$i -lt $Global:HiglightPg4.count;$i++){
            $TempItem=$Global:HiglightPg4[$i]
            if ($TempItem.contains(".")){
                $TempItem=$TempItem.replace(".","_")
            }
            $TempExpression='$CheckBox'+$TempItem+'.backcolor = [System.Drawing.Color]::FromName("Transparent")'
            Invoke-Expression $TempExpression
        }
        $CheckBox1.backcolor = [System.Drawing.Color]::FromName("Transparent")
        $CheckBox2.backcolor = [System.Drawing.Color]::FromName("Transparent")
        $CheckBox9.backcolor = [System.Drawing.Color]::FromName("Transparent")
        $CheckBox17.backcolor = [System.Drawing.Color]::FromName("Transparent")
        $CheckBox18.backcolor = [System.Drawing.Color]::FromName("Transparent")
        $CheckBox19.backcolor = [System.Drawing.Color]::FromName("Transparent")
    
        $Global:HiglightPg4=""
        $Global:HiglightPg4=@()
        
        $initialDirectoryPg4 = [Environment]::GetFolderPath('Desktop')
    
        $OpenFileDialogPg4 = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialogPg4.InitialDirectory = $initialDirectoryPg4
    
        $OpenFileDialogPg4.Filter = 'CIS Results (*.html)|*.html'
    
        $OpenFileDialogPg4.Multiselect = $False
        $AcceptableFile=$False
        $response = $OpenFileDialogPg4.ShowDialog()
        ### Appropriate file type choosen
        if ($response -eq 'OK'){ 
            ###Write-Host 'You selected the file:' $OpenFileDialog.FileName ### File name
            $AcceptableFile=$True
        }
        $global:HTMLFile=[String]$OpenFileDialogPg4.FileName
        
        if ($AcceptableFile){
            ##here
            $Global:ReadFile=$True
            $Global:Remediate=$False
            $Global:FailTestArrayFinal=""
            $Global:FailTestArrayFinal=@()
            $Global:DetailedArray=""
            $Global:DetailedArray=@()
            
            $Global:SectionArray=@(1,2,5,9,17,18,19)
            $Global:SpecificSection=@("1.1","1.2","2.2","2.3.1","2.3.2","2.3.4","2.3.6","2.3.7","2.3.8","2.3.9","2.3.10","2.3.11","2.3.15","2.3.17","5","9.1","9.2","9.3",
        "17.1","17.2","17.3","17.5","17.6","17.7","17.8","17.9","18.1.1","18.1.2","18.2","18.3","18.4","18.5.4","18.5.8","18.5.11","18.5.14","18.5.21","18.5.23.2",
        "18.6","18.8.3","18.8.4","18.8.7","18.8.14","18.8.21","18.8.22.1", "18.8.28", "18.8.34.6","18.8.36","18.8.37","18.9.4","18.9.5","18.9.6","18.9.8","18.9.10.1",
        "18.9.14","18.9.15", "18.9.16", "18.9.17", "18.9.18", "18.9.27.1", "18.9.27.2","18.9.27.3","18.9.27.4","18.9.31","18.9.36","18.9.46","18.9.47.4","18.9.47.5.1", 
        "18.9.47.5.3", "18.9.47.9", "18.9.47.12", "18.9.47.14","18.9.58","18.9.65.2","18.9.65.3.3","18.9.65.3.9","18.9.65.3.11","18.9.66","18.9.67","18.9.75","18.9.81", 
        "18.9.85.1","18.9.85.2","18.9.87","18.9.89","18.9.90","18.9.91","18.9.100","18.9.102.1","18.9.102.2","18.9.104","18.9.105.2","18.9.108.1","18.9.108.2","18.9.108.4", 
        "19.1.3", "19.5.1", "19.7.4", "19.7.8", "19.7.28", "19.7.43")
    
            Write-Output $Global:FailTestArrayFinal | Out-Null
            Write-Output $Global:DetailedArray | Out-Null
            Write-Output $Global:ReadFile |Out-Null
            Write-Output $Global:Remediate |Out-Null
            Write-Output $Global:SpecificSection |Out-Null
            Write-Output $Global:SectionArray | Out-Null
            
                $Global:OutputBoxName="Global:OutputBox"
            $Global:OutputBox.text=""
            Write-Output $Global:OutputBoxName | Out-Null
            
            StartAssessment
            ### Color Check
            $CheckBox1Count=0
            $CheckBox2Count=0
            $CheckBox9Count=0
            $CheckBox17Count=0
            $CheckBox18Count=0
            $CheckBox19Count=0
    
            ###Set the colors
            for ($i=0;$i -lt $Global:HiglightPg4.count;$i++){
                $TempItem=$Global:HiglightPg4[$i]
                if ($TempItem.contains(".")){
                    $TempItem=$TempItem.replace(".","_")
                }
                $TempExpression='$CheckBox'+$TempItem+'.backcolor = [System.Drawing.Color]::Yellow'
                Invoke-Expression $TempExpression
                
                $TempFirstNum=$TempItem.split("_")
                $TempFirstNum=$TempFirstNum[0]
    
                if ($TempFirstNum -eq 1){$CheckBox1Count+=1}
                elseif ($TempFirstNum -eq 2){$CheckBox2Count+=1}
                elseif ($TempFirstNum -eq 9){$CheckBox9Count+=1}
                elseif ($TempFirstNum -eq 17){$CheckBox17Count+=1}
                elseif ($TempFirstNum -eq 18){$CheckBox18Count+=1}
                elseif ($TempFirstNum -eq 19){$CheckBox19Count+=1}
                
                
                if($CheckBox1Count -eq 2){
                    $CheckBox1Count=0
                    $TempExpression='$CheckBox1.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
                elseif($CheckBox2Count -eq 12){
                    $CheckBox2Count=0
                    $TempExpression='$CheckBox2.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
                elseif($CheckBox9Count -eq 3){
                    $CheckBox9Count=0
                    $TempExpression='$CheckBox9.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
                elseif($CheckBox17Count -eq 8){
                    $CheckBox17Count=0
                    $TempExpression='$CheckBox17.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
                elseif($CheckBox18Count -eq 68){
                    $CheckBox18Count=0
                    $TempExpression='$CheckBox18.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
                elseif($CheckBox19Count -eq 6){
                    $CheckBox19Count=0
                    $TempExpression='$CheckBox19.backcolor = [System.Drawing.Color]::Yellow'
                    Invoke-Expression $TempExpression
                }
    
    
            }
    
            ###Reset variable 
            $Global:SpecificSection=@()
            $Global:SectionArray=@(0,0,0,0,0,0,0)
            # $Global:OutputBox.text=""
    
    
            $SelectionLabel.Text = "You have selected: " + $global:HTMLFile
    
            $LabelOptionPg4.Visible=$True
            $LabelPg4.Visible=$True
            $LabelDescPg4.Visible=$True
    
            $ContinueButton.Visible=$True
            $LegendLabelPg4.Visible=$True
            $ChooseLabelPg4.Visible=$True
            $CheckAllBoxes.Visible=$True
            $CheckBox1.Visible=$True
            $CheckBox1_1.Visible=$True
            $CheckBox1_2.Visible=$True
    
            $CheckBox2.Visible=$True
            $CheckBox2_2.Visible=$True
            $CheckBox2_3_1.Visible=$True
            $CheckBox2_3_2.Visible=$True
            $CheckBox2_3_4.Visible=$True
            $CheckBox2_3_6.Visible=$True
            $CheckBox2_3_7.Visible=$True
            $CheckBox2_3_8.Visible=$True
            $CheckBox2_3_9.Visible=$True
            $CheckBox2_3_10.Visible=$True
            $CheckBox2_3_11.Visible=$True
            $CheckBox2_3_15.Visible=$True
            $CheckBox2_3_17.Visible=$True
    
            $CheckBox5.Visible=$True
    
            $CheckBox9.Visible=$True
            $CheckBox9_1.Visible=$True
            $CheckBox9_2.Visible=$True
            $CheckBox9_3.Visible=$True
            
            $CheckBox17.Visible=$True
            $CheckBox17_1.Visible=$True
            $CheckBox17_2.Visible=$True
            $CheckBox17_3.Visible=$True
            $CheckBox17_5.Visible=$True
            $CheckBox17_6.Visible=$True
            $CheckBox17_7.Visible=$True
            $CheckBox17_8.Visible=$True
            $CheckBox17_9.Visible=$True
    
            $CheckBox18.Visible=$True
            $CheckBox18_1_1.Visible=$True
            $CheckBox18_1_2.Visible=$True
            $CheckBox18_2.Visible=$True
            $CheckBox18_3.Visible=$True
            $CheckBox18_4.Visible=$True
            $CheckBox18_5_4.Visible=$True
            $CheckBox18_5_8.Visible=$True
            $CheckBox18_5_11.Visible=$True
            $CheckBox18_5_14.Visible=$True
            $CheckBox18_5_21.Visible=$True
            $CheckBox18_5_23_2.Visible=$True
            $CheckBox18_6.Visible=$True
            $CheckBox18_8_3.Visible=$True
            $CheckBox18_8_4.Visible=$True
            $CheckBox18_8_7.Visible=$True
            $CheckBox18_8_14.Visible=$True
            $CheckBox18_8_21.Visible=$True
            $CheckBox18_8_22_1.Visible=$True
            $CheckBox18_8_28.Visible=$True
            $CheckBox18_8_34_6.Visible=$True
            $CheckBox18_8_36.Visible=$True
            $CheckBox18_8_37.Visible=$True
            $CheckBox18_9_4.Visible=$True
            $CheckBox18_9_5.Visible=$True
            $CheckBox18_9_6.Visible=$True
            $CheckBox18_9_8.Visible=$True
            $CheckBox18_9_10_1.Visible=$True
            $CheckBox18_9_14.Visible=$True
            $CheckBox18_9_15.Visible=$True
            $CheckBox18_9_16.Visible=$True
            $CheckBox18_9_17.Visible=$True
            $CheckBox18_9_18.Visible=$True
            $CheckBox18_9_27_1.Visible=$True
            $CheckBox18_9_27_2.Visible=$True
            $CheckBox18_9_27_3.Visible=$True
            $CheckBox18_9_27_4.Visible=$True
            $CheckBox18_9_31.Visible=$True
            $CheckBox18_9_36.Visible=$True
            $CheckBox18_9_46.Visible=$True
            $CheckBox18_9_47_4.Visible=$True
            $CheckBox18_9_47_5_1.Visible=$True
            $CheckBox18_9_47_5_3.Visible=$True
            $CheckBox18_9_47_9.Visible=$True
            $CheckBox18_9_47_12.Visible=$True
            $CheckBox18_9_47_14.Visible=$True
            $CheckBox18_9_58.Visible=$True
            $CheckBox18_9_65_2.Visible=$True
            $CheckBox18_9_65_3_3.Visible=$True
            $CheckBox18_9_65_3_9.Visible=$True
            $CheckBox18_9_65_3_11.Visible=$True
            $CheckBox18_9_66.Visible=$True
            $CheckBox18_9_67.Visible=$True
            $CheckBox18_9_75.Visible=$True
            $CheckBox18_9_81.Visible=$True
            $CheckBox18_9_85_1.Visible=$True
            $CheckBox18_9_85_2.Visible=$True
            $CheckBox18_9_87.Visible=$True
            $CheckBox18_9_89.Visible=$True
            $CheckBox18_9_90.Visible=$True
            $CheckBox18_9_91.Visible=$True
            $CheckBox18_9_100.Visible=$True
            $CheckBox18_9_102_1.Visible=$True
            $CheckBox18_9_102_2.Visible=$True
            $CheckBox18_9_104.Visible=$True
            $CheckBox18_9_105_2.Visible=$True
            $CheckBox18_9_108_1.Visible=$True
            $CheckBox18_9_108_2.Visible=$True
            $CheckBox18_9_108_4.Visible=$True
    
            $CheckBox19.Visible=$True
            $CheckBox19_1_3.Visible=$True
            $CheckBox19_5_1.Visible=$True
            $CheckBox19_7_4.Visible=$True
            $CheckBox19_7_8.Visible=$True
            $CheckBox19_7_28.Visible=$True
            $CheckBox19_7_43.Visible=$True
            $invisibleObjectPg4.Visible=$True
        }
        else{
            $SelectionLabel.Text ="You have not selected a file"
            # $LabelOptionPg4.Visible=$False
            # $LabelPg4.Visible=$False
            # $LabelDescPg4.Visible=$False
            $ContinueButton.Visible=$False
            $LegendLabelPg4.Visible=$False
            $ChooseLabelPg4.Visible=$False
            $CheckAllBoxes.Visible=$False
            $CheckBox1.Visible=$False
            $CheckBox1_1.Visible=$False
            $CheckBox1_2.Visible=$False
    
            $CheckBox2.Visible=$False
            $CheckBox2_2.Visible=$False
            $CheckBox2_3_1.Visible=$False
            $CheckBox2_3_2.Visible=$False
            $CheckBox2_3_4.Visible=$False
            $CheckBox2_3_6.Visible=$False
            $CheckBox2_3_7.Visible=$False
            $CheckBox2_3_8.Visible=$False
            $CheckBox2_3_9.Visible=$False
            $CheckBox2_3_10.Visible=$False
            $CheckBox2_3_11.Visible=$False
            $CheckBox2_3_15.Visible=$False
            $CheckBox2_3_17.Visible=$False
    
            $CheckBox5.Visible=$False
    
            $CheckBox9.Visible=$False
            $CheckBox9_1.Visible=$False
            $CheckBox9_2.Visible=$False
            $CheckBox9_3.Visible=$False
    
            $CheckBox17.Visible=$False
            $CheckBox17_1.Visible=$False
            $CheckBox17_2.Visible=$False
            $CheckBox17_3.Visible=$False
            $CheckBox17_5.Visible=$False
            $CheckBox17_6.Visible=$False
            $CheckBox17_7.Visible=$False
            $CheckBox17_8.Visible=$False
            $CheckBox17_9.Visible=$False
    
            $CheckBox18.Visible=$False
            $CheckBox18_1_1.Visible=$False
            $CheckBox18_1_2.Visible=$False
            $CheckBox18_2.Visible=$False
            $CheckBox18_3.Visible=$False
            $CheckBox18_4.Visible=$False
            $CheckBox18_5_4.Visible=$False
            $CheckBox18_5_8.Visible=$False
            $CheckBox18_5_11.Visible=$False
            $CheckBox18_5_14.Visible=$False
            $CheckBox18_5_21.Visible=$False
            $CheckBox18_5_23_2.Visible=$False
            $CheckBox18_6.Visible=$False
            $CheckBox18_8_3.Visible=$False
            $CheckBox18_8_4.Visible=$False
            $CheckBox18_8_7.Visible=$False
            $CheckBox18_8_14.Visible=$False
            $CheckBox18_8_21.Visible=$False
            $CheckBox18_8_22_1.Visible=$False
            $CheckBox18_8_28.Visible=$False
            $CheckBox18_8_34_6.Visible=$False
            $CheckBox18_8_36.Visible=$False
            $CheckBox18_8_37.Visible=$False
            $CheckBox18_9_4.Visible=$False
            $CheckBox18_9_5.Visible=$False
            $CheckBox18_9_6.Visible=$False
            $CheckBox18_9_8.Visible=$False
            $CheckBox18_9_10_1.Visible=$False
            $CheckBox18_9_14.Visible=$False
            $CheckBox18_9_15.Visible=$False
            $CheckBox18_9_16.Visible=$False
            $CheckBox18_9_17.Visible=$False
            $CheckBox18_9_18.Visible=$False
            $CheckBox18_9_27_1.Visible=$False
            $CheckBox18_9_27_2.Visible=$False
            $CheckBox18_9_27_3.Visible=$False
            $CheckBox18_9_27_4.Visible=$False
            $CheckBox18_9_31.Visible=$False
            $CheckBox18_9_36.Visible=$False
            $CheckBox18_9_46.Visible=$False
            $CheckBox18_9_47_4.Visible=$False
            $CheckBox18_9_47_5_1.Visible=$False
            $CheckBox18_9_47_5_3.Visible=$False
            $CheckBox18_9_47_9.Visible=$False
            $CheckBox18_9_47_12.Visible=$False
            $CheckBox18_9_47_14.Visible=$False
            $CheckBox18_9_58.Visible=$False
            $CheckBox18_9_65_2.Visible=$False
            $CheckBox18_9_65_3_3.Visible=$False
            $CheckBox18_9_65_3_9.Visible=$False
            $CheckBox18_9_65_3_11.Visible=$False
            $CheckBox18_9_66.Visible=$False
            $CheckBox18_9_67.Visible=$False
            $CheckBox18_9_75.Visible=$False
            $CheckBox18_9_81.Visible=$False
            $CheckBox18_9_85_1.Visible=$False
            $CheckBox18_9_85_2.Visible=$False
            $CheckBox18_9_87.Visible=$False
            $CheckBox18_9_89.Visible=$False
            $CheckBox18_9_90.Visible=$False
            $CheckBox18_9_91.Visible=$False
            $CheckBox18_9_100.Visible=$False
            $CheckBox18_9_102_1.Visible=$False
            $CheckBox18_9_102_2.Visible=$False
            $CheckBox18_9_104.Visible=$False
            $CheckBox18_9_105_2.Visible=$False
            $CheckBox18_9_108_1.Visible=$False
            $CheckBox18_9_108_2.Visible=$False
            $CheckBox18_9_108_4.Visible=$False
    
            $CheckBox19.Visible=$False
            $CheckBox19_1_3.Visible=$False
            $CheckBox19_5_1.Visible=$False
            $CheckBox19_7_4.Visible=$False
            $CheckBox19_7_8.Visible=$False
            $CheckBox19_7_28.Visible=$False
            $CheckBox19_7_43.Visible=$False
            $invisibleObjectPg4.Visible=$False

        }
    })
    $BackButtonPg4 = New-Object System.Windows.Forms.Button
    $BackButtonPg4.Location = New-Object System.Drawing.Size(40,690) #$ContinueButton.Location = New-Object System.Drawing.Size(550,525)
    $BackButtonPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
    $BackButtonPg4.Size = New-Object System.Drawing.Size(125,45)
    $BackButtonPg4.Text = "Back"
    $BackButtonPg4.Visible=$False
    $BackButtonPg4.Anchor = 'Bottom, Left'
    $main_form.Controls.Add($BackButtonPg4)
    ### On Button click
    $BackButtonPg4.Add_Click({
        $SelectionLabel.Text = ""
        ### Goes to Page 1
        $Global:OutputBox.text=""
        HidePage4
        ShowPage1
    
    })

    $invisibleObjectPg4 = New-Object System.Windows.Forms.Label
    $invisibleObjectPg4.Text = " "
    $invisibleObjectPg4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23)
    $invisibleObjectPg4.Location  = New-Object System.Drawing.Size(525,1275)
    $invisibleObjectPg4.AutoSize = $True
    $invisibleObjectPg4.Visible=$False
    $main_form.Controls.Add($invisibleObjectPg4)
    
    
    
    
    ############ Page 5: From Option 2 Continue Button ############

#### Hidden Label for error
### Start Remediation

$Remediation = New-Object System.Windows.Forms.Label
$Remediation.Text = "Remediate Selected Sections of CIS Benchmark"
$Remediation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
$Remediation.Location  = New-Object System.Drawing.Point(5,10)
$Remediation.AutoSize = $True
$Remediation.Visible=$False
$main_form.Controls.Add($Remediation)

$StartRemediationPg5 = New-Object System.Windows.Forms.Label
$StartRemediationPg5.Text = "Results"
$StartRemediationPg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 19, [System.Drawing.FontStyle]::Bold)
$StartRemediationPg5.Location  = New-Object System.Drawing.Point(80,70)
$StartRemediationPg5.AutoSize = $True
$StartRemediationPg5.Visible=$False
$main_form.Controls.Add($StartRemediationPg5)

$StartRemediationButtonPg5 = New-Object System.Windows.Forms.Button
$StartRemediationButtonPg5.Location = New-Object System.Drawing.Size(350,695)
$StartRemediationButtonPg5.Size = New-Object System.Drawing.Size(125,45)
$StartRemediationButtonPg5.anchor="Bottom"
$StartRemediationButtonPg5.Text = "Start Remediation"
$StartRemediationButtonPg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$StartRemediationButtonPg5.Visible=$False
$main_form.Controls.Add($StartRemediationButtonPg5)
### On Button click
$StartRemediationButtonPg5.Add_Click({
    $Global:HandleDeleted=$False
    $Child_formPg5 = New-Object System.Windows.Forms.Form
    ### Title and size of window
    $Child_formPg5.Text ='Confirmation'
    $Child_formPg5.Width = 400
    $Child_formPg5.Height = 200
    $Child_formPg5.startposition = "centerscreen"
    $Child_formPg5.maximumsize = New-Object System.Drawing.Size(400,200)
    $Child_formPg5.MinimumSize  = New-Object System.Drawing.Size(400,200)
    $Child_formPg5.FormBorderStyle = 'Fixed3D'
    $Child_formPg5.MaximizeBox = $false

    ### Label
    $LabelChildPg5 = New-Object System.Windows.Forms.Label
    $LabelChildPg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
    $LabelChildPg5.Location  = New-Object System.Drawing.Point(5,10)
    $LabelChildPg5.Visible=$True
    $LabelChildPg5.text="Start Remediation?"
    $LabelChildPg5.AutoSize = $True
    $Child_formPg5.Controls.Add($LabelChildPg5)
    

    ### Cancel Button
    $CancelButtonChildPg5 = New-Object System.Windows.Forms.Button
    $CancelButtonChildPg5.Location = New-Object System.Drawing.Size(200,125) ###dif of 90
    $CancelButtonChildPg5.Size = New-Object System.Drawing.Size(85,26)
    $CancelButtonChildPg5.Text = "Cancel"
    $CancelButtonChildPg5.Visible=$True
    $Child_formPg5.Controls.Add($CancelButtonChildPg5)
    $CancelButtonChildPg5.Add_Click({
        $Child_formPg5.close()
        
    })

    ### Proceed with remediation button
    $ProceedButtonChildPg5 = New-Object System.Windows.Forms.Button
    $ProceedButtonChildPg5.Location = New-Object System.Drawing.Size(290,125)
    $ProceedButtonChildPg5.Size = New-Object System.Drawing.Size(85,26)
    $ProceedButtonChildPg5.Text = "Proceed"
    $ProceedButtonChildPg5.Visible=$True
    $Child_formPg5.Controls.Add($ProceedButtonChildPg5)
    $ProceedButtonChildPg5.Add_Click({
        ## Show Label
        $FinishRemediationPg5.Visible=$True
        start-sleep -seconds 0.5
        $Global:HandleDeleted=$True
        Write-Output $Global:HandleDeleted
        start-sleep -seconds 0.5
        $Child_formPg5.close()
        

    })
    $Child_formPg5.ShowDialog()

    if((-Not($Child_formPg5.ishandlecreated)) -and ($Global:HandleDeleted)){
        ### Hide buttons
        $BackButtonPg5.Visible=$False
        $StartRemediationButtonPg5.Visible=$False
        ### Reset OutputBox 
        $Global:OutputBox.text=""
        ### Remediating 
        $Global:Remediate=$True
        $Global:ReadFile=$True
        $Global:FailTestArrayFinal=""
        $Global:FailTestArrayFinal=@()
        $Global:DetailedArray=""
        $Global:DetailedArray=@()
        $Global:OutputBoxName="Global:OutputBox"
        $Global:OutputBox.text=""
        $FinishRemediationPg5.Text = "Remediating..."
        start-sleep -seconds 0.5
        StartAssessment

        $FinishRemediationPg5.Text = "Remediation Completed!"

        ### Reinitialise the variables 
        $Global:SpecificSection=@()
        $Global:SectionArray=@(0,0,0,0,0,0,0)

        ### Hide Problems 
        Write-Output $Global:ReadFile |Out-Null
        Write-Output $Global:OutputBoxName | Out-Null
        Write-Output $Global:Remediate |Out-Null
        Write-Output "$Global:SectionArray" | Out-Null
        Write-Output "$Global:SpecificSection" | Out-Null
        Write-Output $Global:FailTestArrayFinal | Out-Null
        Write-Output $Global:DetailedArray | Out-Null
        ### Show buttons
        $ReturnToHomePg5.Visible=$True
    }

})

$FinishRemediationPg5 = New-Object System.Windows.Forms.Label
$FinishRemediationPg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 15)
$FinishRemediationPg5.Location  = New-Object System.Drawing.Point(995,70)
$FinishRemediationPg5.ForeColor='red'
$FinishRemediationPg5.AutoSize = $True
$FinishRemediationPg5.Visible=$False
$main_form.Controls.Add($FinishRemediationPg5)
$ReturnToHomePg5 = New-Object System.Windows.Forms.Button
$ReturnToHomePg5.Location = New-Object System.Drawing.Size(350,695)
$ReturnToHomePg5.Size = New-Object System.Drawing.Size(125,45)
$ReturnToHomePg5.Text = "Back to Home Page"
$ReturnToHomePg5.Anchor= "Bottom, Left"
$ReturnToHomePg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ReturnToHomePg5.Visible=$False
$main_form.Controls.Add($ReturnToHomePg5)
### On Button click
$ReturnToHomePg5.Add_Click({
    ### Goes to Page 1
    $Global:OutputBox.text=""
    Write-Host $Global:OutputBox.text
    $FinishRemediationPg5.Text= ""

    HidePage5
    ShowPage1

})

$BackButtonPg5 = New-Object System.Windows.Forms.Button
$BackButtonPg5.Location = New-Object System.Drawing.Size(40,695)
$BackButtonPg5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg5.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg5.Text = "Back"
$BackButtonPg5.Visible=$False
$BackButtonPg5.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg5)
### On Button click
$BackButtonPg5.Add_Click({
    ### Goes to Page 4, Option 2
    HidePage5
    ShowPage4

})

############ Page 6: Option 3 ############
$LabelPg6 = New-Object System.Windows.Forms.Label
$LabelPg6.Text = "Select files before and after remediation"
$LabelPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
### Location of text on the windows form
$LabelPg6.Location  = New-Object System.Drawing.Point(5,10)
$LabelPg6.AutoSize = $True
$main_form.Controls.Add($LabelPg6)
$LabelPg6.Visible=$False

$LabelDescPg6 = New-Object System.Windows.Forms.Label
$LabelDescPg6.Text = ""
$LabelDescPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$LabelDescPg6.Location  = New-Object System.Drawing.Point(7,50)
$LabelDescPg6.AutoSize = $True
$main_form.Controls.Add($LabelDescPg6)
$LabelDescPg6.Visible=$False

### First File
$Label1Page6 = New-Object System.Windows.Forms.Label
$Label1Page6.Text = "First File (Before Remediation)"
$Label1Page6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$Label1Page6.Location  = New-Object System.Drawing.Point(7,80)
$Label1Page6.AutoSize = $True
$Label1Page6.Visible=$False
$main_form.Controls.Add($Label1Page6)

$Label1APage6 = New-Object System.Windows.Forms.Label
$Label1APage6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$Label1APage6.Location  = New-Object System.Drawing.Point(7,120)
$Label1APage6.AutoSize = $True
$Label1APage6.Visible=$False
$main_form.Controls.Add($Label1APage6)

### Select Button
$SelectFile1ButtonPg6 = New-Object System.Windows.Forms.Button
$SelectFile1ButtonPg6.Location = New-Object System.Drawing.Size(10,160)
$SelectFile1ButtonPg6.Size = New-Object System.Drawing.Size(125,45)
$SelectFile1ButtonPg6.Text = "Select First File"
$SelectFile1ButtonPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$main_form.Controls.Add($SelectFile1ButtonPg6)
$SelectFile1ButtonPg6.Visible=$False
### On Button click
$SelectFile1ButtonPg6.Add_Click({
    
    $initialDirectoryPg6 = [Environment]::GetFolderPath('Desktop')

    $OpenFileDialogPg6 = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialogPg6.InitialDirectory = $initialDirectoryPg6

    $OpenFileDialogPg6.Filter = 'CIS Results (*.html)|*.html'

    $OpenFileDialogPg6.Multiselect = $False
    $AcceptableFile1Pg6=$False
    $response = $OpenFileDialogPg6.ShowDialog()
    ### Appropriate file type choosen
    if ($response -eq 'OK'){ 
        ###Write-Host 'You selected the file:' $OpenFileDialog.FileName ### File name
        $AcceptableFile1Pg6=$True
    }
    $global:HTMLFile1=[String]$OpenFileDialogPg6.FileName
    
    if ($AcceptableFile1Pg6){
        $Label1APage6.Text = "You have selected: " + $global:HTMLFile1

    }
    else{
        $Label1APage6.Text ="You have not selected a file"
    }

    if((($Label1APage6.Text -ne "You have not selected a file") -and ($Label1APage6.Text -ne "")) -and (($Label1BPage6.Text -ne "You have not selected a file") -and ($Label1BPage6.Text -ne ""))){
        $ContinueButtonPg6.Visible=$True
    }
    else{
        $ContinueButtonPg6.Visible=$False
    }

})

#### Second file
$Label2Page6 = New-Object System.Windows.Forms.Label
$Label2Page6.Text = "Second File (After Remediation)"
$Label2Page6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$Label2Page6.Location  = New-Object System.Drawing.Point(7,230)
$Label2Page6.AutoSize = $True
$Label2Page6.Visible=$False
$main_form.Controls.Add($Label2Page6)

$Label1BPage6 = New-Object System.Windows.Forms.Label
$Label1BPage6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$Label1BPage6.Location  = New-Object System.Drawing.Point(7,260)
$Label1BPage6.AutoSize = $True
$Label1BPage6.Visible=$False
$main_form.Controls.Add($Label1BPage6)


### Select Button
$SelectFile2ButtonPg6 = New-Object System.Windows.Forms.Button
$SelectFile2ButtonPg6.Location = New-Object System.Drawing.Size(10,300)
$SelectFile2ButtonPg6.Size = New-Object System.Drawing.Size(125,45)
$SelectFile2ButtonPg6.Text = "Select Second File"
$SelectFile2ButtonPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$main_form.Controls.Add($SelectFile2ButtonPg6)
$SelectFile2ButtonPg6.Visible=$False
### On Button click
$SelectFile2ButtonPg6.Add_Click({
    
    $initialDirectory2Pg6 = [Environment]::GetFolderPath('Desktop')

    $OpenFileDialog2Pg6 = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog2Pg6.InitialDirectory = $initialDirectory2Pg6

    $OpenFileDialog2Pg6.Filter = 'CIS Results (*.html)|*.html'

    $OpenFileDialog2Pg6.Multiselect = $False
    $AcceptableFile2Pg6=$False
    $response = $OpenFileDialog2Pg6.ShowDialog()
    ### Appropriate file type choosen
    if ($response -eq 'OK'){ 
        ###Write-Host 'You selected the file:' $OpenFileDialog.FileName ### File name
        $AcceptableFile2Pg6=$True
    }
    $global:HTMLFile2=[String]$OpenFileDialog2Pg6.FileName
    
    if ($AcceptableFile2Pg6){
        $Label1BPage6.Text = "You have selected: " + $global:HTMLFile2

    }
    else{
        $Label1BPage6.Text ="You have not selected a file"
    }
    if((($Label1APage6.Text -ne "You have not selected a file") -and ($Label1APage6.Text -ne "")) -and (($Label1BPage6.Text -ne "You have not selected a file") -and ($Label1BPage6.Text -ne ""))){
        $ContinueButtonPg6.Visible=$True
    }
    else{
        $ContinueButtonPg6.Visible=$False
    }
})

$ContinueButtonPg6 = New-Object System.Windows.Forms.Button
$ContinueButtonPg6.Location = New-Object System.Drawing.Size(990,695)
$ContinueButtonPg6.Size = New-Object System.Drawing.Size(125,45)
$ContinueButtonPg6.Anchor = 'Bottom, Right'
$ContinueButtonPg6.Text = "Continue"
$ContinueButtonPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueButtonPg6.Visible=$False
$main_form.Controls.Add($ContinueButtonPg6)
$ContinueButtonPg6.Add_Click({
    $Label1APage6.Text = ""
    $Label1BPage6.Text = ""
    HidePage6
    ShowPage7
    
})

$BackButtonPg6 = New-Object System.Windows.Forms.Button
$BackButtonPg6.Location = New-Object System.Drawing.Size(40,695)
$BackButtonPg6.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg6.Text = "Back"
$BackButtonPg6.Visible=$False
$BackButtonPg6.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg6)
### On Button click
$BackButtonPg6.Add_Click({
    $Label1APage6.Text = ""
    $Label1BPage6.Text = ""
    ### Goes to Page 1
    HidePage6
    ShowPage1

})

############ Page 7: Option 3 ############

$CompareLabelPg7 = New-Object System.Windows.Forms.Label
$CompareLabelPg7.Text = "Compare both files"
$CompareLabelPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23,[System.Drawing.FontStyle]::Bold)
$CompareLabelPg7.Location  = New-Object System.Drawing.Point(6,8)
$CompareLabelPg7.AutoSize = $True
$CompareLabelPg7.Visible=$False
$main_form.Controls.Add($CompareLabelPg7)

#### Label 1 
$CompareLabel1APg7 = New-Object System.Windows.Forms.Label
$CompareLabel1APg7.Text = "Before Remediation"
$CompareLabel1APg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$CompareLabel1APg7.Location  = New-Object System.Drawing.Point(210,60)
$CompareLabel1APg7.AutoSize = $True
$CompareLabel1APg7.Visible=$False
$main_form.Controls.Add($CompareLabel1APg7)

#### Label 2
$CompareLabel1BPg7 = New-Object System.Windows.Forms.Label
$CompareLabel1BPg7.Text = "After Remediation"
$CompareLabel1BPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$CompareLabel1BPg7.Location  = New-Object System.Drawing.Point(940,60)
$CompareLabel1BPg7.AutoSize = $True
$CompareLabel1BPg7.Visible=$False
$main_form.Controls.Add($CompareLabel1BPg7)

$FinishRemediationPg7 = New-Object System.Windows.Forms.Label
$FinishRemediationPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 15)
$FinishRemediationPg7.Location  = New-Object System.Drawing.Point(600,30)
$FinishRemediationPg7.ForeColor='red'
$FinishRemediationPg7.AutoSize = $True
$FinishRemediationPg7.Visible=$False
$main_form.Controls.Add($FinishRemediationPg7)

### Second red label
$FinishRemediationAPg7 = New-Object System.Windows.Forms.Label
$FinishRemediationAPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 15)
$FinishRemediationAPg7.Location  = New-Object System.Drawing.Point(1340,30)
$FinishRemediationAPg7.ForeColor='red'
$FinishRemediationAPg7.AutoSize = $True
$FinishRemediationAPg7.Visible=$False
$main_form.Controls.Add($FinishRemediationAPg7)

$CompareLabelButtonPg7 = New-Object System.Windows.Forms.Button
$CompareLabelButtonPg7.Location = New-Object System.Drawing.Size(900,695)
$CompareLabelButtonPg7.Size = New-Object System.Drawing.Size(125,45)
$CompareLabelButtonPg7.Text = "Start Assessment"
$CompareLabelButtonPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$CompareLabelButtonPg7.Visible=$False
$CompareLabelButtonPg7.Anchor = 'Bottom, Right'
$main_form.Controls.Add($CompareLabelButtonPg7)
### On Button click
$CompareLabelButtonPg7.Add_Click({

    ### Hide buttons
    $BackButtonPg7.Visible=$False
    $CompareLabelButtonPg7.Visible=$False
    ### Set the Variables
    $Global:SectionArray=@(1,2,5,9,17,18,19)
    $Global:SpecificSection=@("1.1","1.2","2.2","2.3.1","2.3.2","2.3.4","2.3.6","2.3.7","2.3.8","2.3.9","2.3.10","2.3.11","2.3.15","2.3.17","5","9.1","9.2","9.3",
    "17.1","17.2","17.3","17.5","17.6","17.7","17.8","17.9","18.1.1","18.1.2","18.2","18.3","18.4","18.5.4","18.5.8","18.5.11","18.5.14","18.5.21","18.5.23.2",
    "18.6","18.8.3","18.8.4","18.8.7","18.8.14","18.8.21","18.8.22.1", "18.8.28", "18.8.34.6","18.8.36","18.8.37","18.9.4","18.9.5","18.9.6","18.9.8","18.9.10.1",
    "18.9.14","18.9.15", "18.9.16", "18.9.17", "18.9.18", "18.9.27.1", "18.9.27.2","18.9.27.3","18.9.27.4","18.9.31","18.9.36","18.9.46","18.9.47.4","18.9.47.5.1", 
    "18.9.47.5.3", "18.9.47.9", "18.9.47.12", "18.9.47.14","18.9.58","18.9.65.2","18.9.65.3.3","18.9.65.3.9","18.9.65.3.11","18.9.66","18.9.67","18.9.75","18.9.81", 
    "18.9.85.1","18.9.85.2","18.9.87","18.9.89","18.9.90","18.9.91","18.9.100","18.9.102.1","18.9.102.2","18.9.104","18.9.105.2","18.9.108.1","18.9.108.2","18.9.108.4", 
    "19.1.3", "19.5.1", "19.7.4", "19.7.8", "19.7.28", "19.7.43")

    ### First File
    #### Show Labels
    $FinishRemediationPg7.Visible=$True
    $FinishRemediationAPg7.Visible=$True
    $FinishRemediationPg7.Text = "Assessing First File..."
    ### Reset OutputBox
    $Global:OutputBox.text=""
    $Global:OutputBox.text+="`r`n Assessment of First File `r`n"
    ### Insert first selected file
    $global:HTMLFile=$global:HTMLFile1

    ### Change label
    # $FinishRemediationPg7.Text = "Assessing First File!"
    ### Reinitialising variable
    $Global:ArrayOfArrays=""
    $Global:ArrayOfArrays=@()
    $Global:ReadFile=$True
    ### Not Remediating
    $Global:Remediate=$False

    $Global:FailTestArrayFinal=""
    $Global:FailTestArrayFinal=@()
    $Global:DetailedArray=""
    $Global:DetailedArray=@()
    
    $Global:OutputBoxName="Global:OutputBox"
    Write-Output $Global:OutputBoxName | Out-Null
    $FinishRemediationPg7.Text = "Assessment Completed!" 
    $Global:OutputBox.text=""
    StartAssessment
    $Global:FirstFile=$Global:ArrayOfArrays

    ### Object from first file (not needed)
    
    if (-Not ($Global:AllCorrect)){
        $Global:OutputBox.text+="Score From First File `r`n"
        for($i=0;$i -lt $Global:FirstFile.Length;$i+=5){

            $Pass2+= $Global:FirstFile[$i+1]
            $Fail2+= $Global:FirstFile[$i+2]
            $ErrorValue2+= $Global:FirstFile[$i+3]
            $Unknown2+= $Global:FirstFile[$i+4]

            $TempObject=[PSCustomObject]@{
                Title = $Global:FirstFile[$i]
                Pass  = $Global:FirstFile[$i+1]
                Fail  = $Global:FirstFile[$i+2]
                Error = $Global:FirstFile[$i+3]
                unknown =$Global:FirstFile[$i+4]
            }
            $Global:OutputBox.text+="`r`n Section: " + $Global:FirstFile[$i] + "`r`n"
            $Global:OutputBox.text+="Pass:    " + $Global:FirstFile[$i+1] + "`r`n"
            $Global:OutputBox.text+="Fail:    " + $Global:FirstFile[$i+2] + "`r`n"
            $Global:OutputBox.text+="Error:   " + $Global:FirstFile[$i+3] + "`r`n"
            $Global:OutputBox.text+="Unknown:  " + $Global:FirstFile[$i+4] + "`r`n"
            $Global:OutputBox.text+="`r`n"
            $Global:FirstFileArray+=$TempObject
        }
    }
    $Global:OutputBox.text+="`r`n Assessment Completed! `r`n"
    # $TempArray=$Global:OutputBox.text -split "\r \n" 
    # Write-Host $TempArray.GetType()
    # Write-Host $TempArray

    # Write-Host '  `r`n'
    # Write-Host '  sPACCE'
    # Write-Host '  `r`n'
    ### Reinitialising variable
    $Global:ArrayOfArrays=""
    $Global:ArrayOfArrays=@()

    $Global:AllCorrect=$False

    ### Second File
    # $FinishRemediationPg7.Text = "`r`n Assessing Second File..."
    $Global:OutputBox1.text+="`r`n Assessment of Second File `r`n"
    ### Insert second selected file
    $global:HTMLFile=$global:HTMLFile2
    $FinishRemediationAPg7.Text = "Assessing Second File!"
    $Global:FailTestArrayFinal=""
    $Global:FailTestArrayFinal=@()
    $Global:DetailedArray=""
    $Global:DetailedArray=@()

    $Global:OutputBoxName="OutputBox1" 
    $OutputBox1.text=""
    StartAssessment

    $Global:SecondFile=$Global:ArrayOfArrays
    # Write-Host "Second file"

    
    ### Object from second file
    $Pass=0
    $Fail=0
    $ErrorValue=0
    $Unknown=0
    
        $Global:OutputBox1.text+="Score From Second File `r`n"
        for($i=0;$i -lt $Global:SecondFile.Length;$i+=5){
            $Pass+= $Global:SecondFile[$i+1]
            $Fail+= $Global:SecondFile[$i+2]
            $ErrorValue+= $Global:SecondFile[$i+3]
            $Unknown+= $Global:SecondFile[$i+4]

            $TempObject=[PSCustomObject]@{
                Title = $Global:SecondFile[$i]
                Pass  = $Global:SecondFile[$i+1]
                Fail  = $Global:SecondFile[$i+2]
                Error = $Global:SecondFile[$i+3]
                unknown =$Global:SecondFile[$i+4]
            }
            $Global:OutputBox1.text+="`r`n Section: " + $Global:SecondFile[$i] + "`r`n"
            $Global:OutputBox1.text+="Pass:    " + $Global:SecondFile[$i+1] + "`r`n"
            $Global:OutputBox1.text+="Fail:    " + $Global:SecondFile[$i+2] + "`r`n"
            $Global:OutputBox1.text+="Error:   " + $Global:SecondFile[$i+3] + "`r`n"
            $Global:OutputBox1.text+="Unknown:  " + $Global:SecondFile[$i+4] + "`r`n"
            $Global:OutputBox1.text+="`r`n"
            $Global:SecondFileArray+=$TempObject
        }
    
    $Global:OutputBox1.text+="`r`n Assessment Completed! `r`n"

    $FinishRemediationAPg7.Text = "Assessment Completed!" 
    
    ### Make the pie chart here (Include positioning of graph)

    $PieChartObjects=@{
        Pass    = $Pass
        Fail    = $Fail
        Error   = $ErrorValue
        Unknown = $Unknown
        Section1 = $Section1
        Section2 = $Section2
        Section5 = $Section5
        Section9 = $Section9
        Section17 = $Section17
        Section18 = $Section18
        Section19 = $Section19
    }
    ### Start of code

   #chart 1 after (RIGHT side)

    $DataArray = @("Passed", "Failed", "Error", "Unknown")
    $DataValues=@($Pass,$Fail,$ErrorValue,$Unknown)

    $Global:Chart.Visible



   # create chart object
   $Global:Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
   $Global:Chart.Width = 450
   $Global:Chart.Height = 350
   $Global:Chart.Left = 20
   $Global:Chart.Top = 1
   $Global:Chart.Location = New-Object System.Drawing.Size(1010,525)
   $Global:Chart.Visible = $True
   # $Global:Chart.Title = $global:HTMLFile2

   # chart colour palette (must match data array order)
   $Global:Chart.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
   $Global:Chart.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red, [System.Drawing.Color]::Gold, [System.Drawing.Color]::Brown )

   # create a chartarea to draw on and add to chart
   $Global:ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
   # $Global:ChartArea.Backgroundcolor="Orange"
   $Global:Chart.ChartAreas.Add($Global:ChartArea)

   # add data to chart
   [void]$Global:Chart.Series.Add("Data")
   $Global:Chart.Series["Data"].Points.DataBindXY($DataArray, $DataValues)
   $Global:Chart.Series["Data"].ChartType = "Pie"
   $Global:Chart.Series["Data"]["PieLabelStyle"] = "Outside"
   $Global:Chart.Series["Data"]["PieDrawingStyle"] = "Concave"
   $Global:Chart.Series["Data"]["PieLineColor"] = "Black"
   ($Global:Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
   $Global:Chart.Series["Data"]['PieLabelStyle'] = 'Disabled'

   # Legend
   $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
   $Legend.IsEquallySpacedItems = $True
   $Legend.BorderColor = 'Black'
   $Global:Chart.Legends.Add($Legend)
   $Global:Chart.Series["Data"].LegendText = "#VALX (#PERCENT)"
   $main_form.Controls.Add($Global:Chart)




   # $main_form.ShowDialog()


   # chart 2 before (LEFT side)
    $DataArray2 = @("Passed", "Failed", "Error", "Unknown")
    $DataValues2=@($Pass2,$Fail2,$ErrorValue2,$Unknown2)

   # create chart object
   $Global:Chart2 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
   $Global:Chart2.Width = 450
   $Global:Chart2.Height = 350
   $Global:Chart2.Left = 20
   $Global:Chart2.Top = 1
   $Global:Chart2.Location = New-Object System.Drawing.Size(270,525)
   $Global:Chart2.Visible = $True
   # $Global:Chart.Title = $global:HTMLFile2

   # chart colour palette (must match data array order)
   $Global:Chart2.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
   $Global:Chart2.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red, [System.Drawing.Color]::Gold, [System.Drawing.Color]::Brown )

   # create a chartarea to draw on and add to chart
   $Global:ChartArea2 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
   # $Global:ChartArea.Backgroundcolor="Orange"
   $Global:Chart2.ChartAreas.Add($Global:ChartArea2)

   # add data to chart
   [void]$Global:Chart2.Series.Add("Data")
   $Global:Chart2.Series["Data"].Points.DataBindXY($DataArray2, $DataValues2)
   $Global:Chart2.Series["Data"].ChartType = "Pie"
   $Global:Chart2.Series["Data"]["PieLabelStyle"] = "Outside"
   $Global:Chart2.Series["Data"]["PieDrawingStyle"] = "Concave"
   $Global:Chart2.Series["Data"]["PieLineColor"] = "Black"
   ($Global:Chart2.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
   $Global:Chart2.Series["Data"]['PieLabelStyle'] = 'Disabled'

   # Legend
   $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
   $Legend.IsEquallySpacedItems = $True
   $Legend.BorderColor = 'Black'
   $Global:Chart2.Legends.Add($Legend)
   $Global:Chart2.Series["Data"].LegendText = "#VALX (#PERCENT)"
   $main_form.Controls.Add($Global:Chart2)




    # $main_form.ShowDialog()

  #### Fourth Pie chart (LEFT pie chart sections failed)
  $Section1A=0
  $Section2A=0
  $Section5A=0
  $Section9A=0
  $Section17A=0
  $Section18A=0
  $Section19A=0
  for ($i=0;$i -lt $Global:FirstFileArray.length;$i++){
      if($i -eq 0){$Section1A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 1){$Section2A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 2){$Section5A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 3){$Section9A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 4){$Section17A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 5){$Section18A=$Global:FirstFileArray[$i].Fail}
      if($i -eq 6){$Section19A=$Global:FirstFileArray[$i].Fail}
  }


   
    $DataArray = @("Section 1", "Section 2", "Section 5", "Section 9", "Section 17", "Section 18", "Section 19")
    $DataValues=@($Section1A,$Section2A,$Section5A,$Section9A,$Section17A,$Section18A,$Section19A)
  # create chart object
  $Global:Chart4 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
  $Global:Chart4.Width = 450
  $Global:Chart4.Height = 350
  $Global:Chart4.Left = 20
  $Global:Chart4.Top = 1
  $Global:Chart4.Location = New-Object System.Drawing.Size(270,900)
  $Global:Chart4.Visible = $True
  ### Title
  $Chart4 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
  $Chart4.Text = 'Incorrect Configuration from each Section'
  $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
  $Chart4.Font =$Font
  $Global:Chart4.Titles.Add($Chart4)

  # chart colour palette (must match data array order)
  $Global:Chart4.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None ###brown, gold, red ,green
  $Global:Chart4.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Blue, [System.Drawing.Color]::Purple, [System.Drawing.Color]::HotPink, [System.Drawing.Color]::Red, [System.Drawing.Color]::Orange )

  # create a chartarea to draw on and add to chart
  $Global:Chart4Area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
  # $Global:Chart4.Backgroundcolor="Orange"
  $Global:Chart4.ChartAreas.Add($Global:Chart4Area)

  # add data to chart
  [void]$Global:Chart4.Series.Add("Data")
  $Global:Chart4.Series["Data"].Points.DataBindXY($DataArray, $DataValues)
  $Global:Chart4.Series["Data"].ChartType = "Pie"
  $Global:Chart4.Series["Data"]["PieLabelStyle"] = "Outside"
  $Global:Chart4.Series["Data"]["PieDrawingStyle"] = "Concave"
  $Global:Chart4.Series["Data"]["PieLineColor"] = "Black"
  ($Global:Chart4.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
  $Global:Chart4.Series["Data"]['PieLabelStyle'] = 'Disabled'

  # Legend
  $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
  $Legend.IsEquallySpacedItems = $True
  $Legend.BorderColor = 'Black'
  $Global:Chart4.Legends.Add($Legend)
  $Global:Chart4.Series["Data"].LegendText = "#VALX (#PERCENT)"
  $main_form.Controls.Add($Global:Chart4)

  
#### 3rd Pie chart (RIGHT side Sections failed)
$Section1=0
$Section2=0
$Section5=0
$Section9=0
$Section17=0
$Section18=0
$Section19=0
for ($i=0;$i -lt $Global:SecondFileArray.length;$i++){
  if($i -eq 0){$Section1=$Global:SecondFileArray[$i].Fail}
  if($i -eq 1){$Section2=$Global:SecondFileArray[$i].Fail}
  if($i -eq 2){$Section5=$Global:SecondFileArray[$i].Fail}
  if($i -eq 3){$Section9=$Global:SecondFileArray[$i].Fail}
  if($i -eq 4){$Section17=$Global:SecondFileArray[$i].Fail}
  if($i -eq 5){$Section18=$Global:SecondFileArray[$i].Fail}
  if($i -eq 6){$Section19=$Global:SecondFileArray[$i].Fail}
}


$DataArray = @("Section 1", "Section 2", "Section 5", "Section 9", "Section 17", "Section 18", "Section 19")
$DataValues=@($Section1,$Section2,$Section5,$Section9,$Section17,$Section18,$Section19)
# create chart object
$Global:Chart3 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
$Global:Chart3.Width = 450
$Global:Chart3.Height = 350
$Global:Chart3.Left = 20
$Global:Chart3.Top = 1
$Global:Chart3.Location = New-Object System.Drawing.Size(1010,900)
$Global:Chart3.Visible = $True

#Title
$Chart3 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
  $Chart3.Text = 'Incorrect Configuration from each Section'
  $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
  $Chart3.Font =$Font
  $Global:Chart3.Titles.Add($Chart3)


# chart colour palette (must match data array order)
$Global:Chart3.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None ###brown, gold, red ,green
$Global:Chart3.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Cyan, [System.Drawing.Color]::Blue, [System.Drawing.Color]::Purple, [System.Drawing.Color]::HotPink, [System.Drawing.Color]::Red, [System.Drawing.Color]::Orange )


 # create a chartarea to draw on and add to chart
 $Global:ChartArea3 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
 # $Global:ChartArea.Backgroundcolor="Orange"
 $Global:Chart3.ChartAreas.Add($Global:ChartArea3)

 # add data to chart
 [void]$Global:Chart3.Series.Add("Data")
 $Global:Chart3.Series["Data"].Points.DataBindXY($DataArray, $DataValues)
 $Global:Chart3.Series["Data"].ChartType = "Pie"
 $Global:Chart3.Series["Data"]["PieLabelStyle"] = "Outside"
 $Global:Chart3.Series["Data"]["PieDrawingStyle"] = "Concave"
 $Global:Chart3.Series["Data"]["PieLineColor"] = "Black"
 ($Global:Chart3.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
 $Global:Chart3.Series["Data"]['PieLabelStyle'] = 'Disabled'

 # Legend
 $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
 $Legend.IsEquallySpacedItems = $True
 $Legend.BorderColor = 'Black'
 $Global:Chart3.Legends.Add($Legend)
 $Global:Chart3.Series["Data"].LegendText = "#VALX (#PERCENT)"
 $main_form.Controls.Add($Global:Chart3)





    #### End of code

    
    ### Reinitialise the variables
    $Global:SpecificSection=@()
    $Global:SectionArray=@(0,0,0,0,0,0,0)
    ### Hide problems
    Write-Output $global:HTMLFile | Out-Null
    Write-Output "$Global:SpecificSection" | Out-Null
    Write-Output "$Global:SectionArray" | Out-Null
    Write-Output $Global:ReadFile |Out-Null
    Write-Output $Global:Remediate |Out-Null
    Write-Output $PieChartObjects | Out-Null
    Write-Output $Global:FailTestArrayFinal | Out-Null
    Write-Output $Global:DetailedArray | Out-Null
    ### Show button
    $OutcomeResult3.text+=" Overall Results: `r`n Number of Pass: " + $Pass + " `r`n Number of Fails: " + $Fail + "`r`n Number of Error: " + $ErrorValue + "`r`n Number of Unknown: " + $Unknown
    $OutcomeResult3.Visible=$True
    $OutcomeResult4.text+=" Fails from each section: `r`n Section 1: " + $Section1 + " `r`n Section 2: " + $Section2 + "`r`n Section 5: " + $Section5 + "`r`n Section 9: " + $Section9 + "`r`n Section 17: " + $Section17 + "`r`n Section 18: " + $Section18 + "`r`n Section 19: " + $Section19
    $OutcomeResult4.Visible=$True
    $OutcomeResult5.text+=" Overall Results: `r`n Number of Pass: " + $Pass2 + " `r`n Number of Fails: " + $Fail2 + "`r`n Number of Error: " + $ErrorValue2 + "`r`n Number of Unknown: " + $Unknown2
    $OutcomeResult5.Visible=$True
    $OutcomeResult6.text+=" Fails from each section: `r`n Section 1: " + $Section1A + " `r`n Section 2: " + $Section2A + "`r`n Section 5: " + $Section5A + "`r`n Section 9: " + $Section9A + "`r`n Section 17: " + $Section17A + "`r`n Section 18: " + $Section18A + "`r`n Section 19: " + $Section19A
    $OutcomeResult6.Visible=$True
    $ReturnToHomePg7.Visible=$True

})

$OutcomeResult3 = New-Object System.Windows.Forms.Label
$OutcomeResult3.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult3.Location  = New-Object System.Drawing.Point(1500,525)
$OutcomeResult3.AutoSize = $True
$OutcomeResult3.Visible=$False
$main_form.Controls.Add($OutcomeResult3)

$OutcomeResult4 = New-Object System.Windows.Forms.Label
$OutcomeResult4.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult4.Location = New-Object System.Drawing.Point(1500,900)
$OutcomeResult4.AutoSize = $True
$OutcomeResult4.Visible=$False
$main_form.Controls.Add($OutcomeResult4)

$OutcomeResult5 = New-Object System.Windows.Forms.Label
$OutcomeResult5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult5.Location  = New-Object System.Drawing.Point(750,525)
$OutcomeResult5.AutoSize = $True
$OutcomeResult5.Visible=$False
$main_form.Controls.Add($OutcomeResult5)

$OutcomeResult6 = New-Object System.Windows.Forms.Label
$OutcomeResult6.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutcomeResult6.Location = New-Object System.Drawing.Point(750,900)
$OutcomeResult6.AutoSize = $True
$OutcomeResult6.Visible=$False
$main_form.Controls.Add($OutcomeResult6)

$ReturnToHomePg7 = New-Object System.Windows.Forms.Button
$ReturnToHomePg7.Location = New-Object System.Drawing.Size(60,1300)
$ReturnToHomePg7.Size = New-Object System.Drawing.Size(125,45)
$ReturnToHomePg7.Text = "Back to Home Page"
$ReturnToHomePg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ReturnToHomePg7.Visible=$False
$main_form.Controls.Add($ReturnToHomePg7)
### On Button click
$ReturnToHomePg7.Add_Click({
    ### Goes to Page 1
    $Global:OutputBox.text=""
    $Global:OutputBox1.text=""
    $OutcomeResult3.text=""
    $OutcomeResult4.text=""
    $OutcomeResult5.text=""
    $OutcomeResult6.text=""
    HidePage7
    ShowPage1

})

$BackButtonPg7 = New-Object System.Windows.Forms.Button
$BackButtonPg7.Location = New-Object System.Drawing.Size(220,695)
$BackButtonPg7.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg7.Text = "Back"
$BackButtonPg7.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg7.Visible=$False
$BackButtonPg7.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg7)
### On Button click
$BackButtonPg7.Add_Click({
    ### Goes to Page 6, Option 3
    HidePage7
    ShowPage6

})

##### Page 8

# $LabelPg9 = New-Object System.Windows.Forms.Label
# $LabelPg9.Text = "Select a file to Assess"
# $LabelPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 15, [System.Drawing.FontStyle]::Bold)
# $LabelPg9.Location  = New-Object System.Drawing.Point(5,10)
# $LabelPg9.Text="Click on the button to proceed to CIS Benchmark"
# $LabelPg9.AutoSize = $True
# $main_form.Controls.Add($LabelPg9)
# $LabelPg9.Visible=$False



#### Page 9

### Page 9 OutputBox
$OutputBox9 = New-Object System.Windows.Forms.TextBox
$OutputBox9.Location= New-Object System.Drawing.Size(30,90)
$OutputBox9.Size = New-Object System.Drawing.Size(650,550)
$OutputBox9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutputBox9.ReadOnly=$True
$OutputBox9.Multiline = $True
$OutputBox9.Visible=$False
$OutputBox9.ForeColor="black"
$OutputBox9.Scrollbars = "Vertical" 
$main_form.Controls.Add($OutputBox9)

#Label
$LabelOptionPg9 = New-Object System.Windows.Forms.Label
$LabelOptionPg9.Text = "Check Computer Configuration by selecting a configuration file"
$LabelOptionPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
$LabelOptionPg9.Location  = New-Object System.Drawing.Point(5,10)
$LabelOptionPg9.AutoSize = $True
$main_form.Controls.Add($LabelOptionPg9)
$LabelOptionPg9.Visible=$False

#Description
$LabelDescPg9 = New-Object System.Windows.Forms.Label
$LabelDescPg9.Text = "Select a configuration file that is of txt file type to run."
$LabelDescPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$LabelDescPg9.Location  = New-Object System.Drawing.Point(10,50)
$LabelDescPg9.AutoSize = $True
$main_form.Controls.Add($LabelDescPg9)
$LabelDescPg9.Visible=$False

#Readme section
$ReadmeBox9 = New-Object System.Windows.Forms.TextBox
$ReadmeBox9.Text = 
"group1 cross-checks against member1 members
group2 cross-checks against member2 members 
and so on
only use a comma when adding multiple members
and no space after the commas

drive=E
choose the drive
check if folder1 and so on exists under the drive
folder1 cross-checks against
identity1, right1, admin1 and folderadmin
identity1 and right1 are cross-checked

for right1 and so on
Read, Execute -> ReadAndExecute
always include a (, Synchronize) at the end
split the rights with a comma and a space

do not tamper with folderadmin
it remains as the default builtin administrator name"
$ReadmeBox9.Location= New-Object System.Drawing.Size(685,90)
$ReadmeBox9.Size = New-Object System.Drawing.Size(365,550)
$ReadmeBox9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ReadmeBox9.ReadOnly=$True
$ReadmeBox9.Multiline = $True
$ReadmeBox9.Visible=$False
$ReadmeBox9.ForeColor="black"
$main_form.Controls.Add($ReadmeBox9)

### Select Button
$SelectFileButtonPg9 = New-Object System.Windows.Forms.Button
$SelectFileButtonPg9.Location = New-Object System.Drawing.Size(850,695)
$SelectFileButtonPg9.Size = New-Object System.Drawing.Size(125,45)
$SelectFileButtonPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$SelectFileButtonPg9.Text = "Select File"
$SelectFileButtonPg9.Anchor = 'Bottom, Right'
$SelectFileButtonPg9.Visible=$False
$main_form.Controls.Add($SelectFileButtonPg9)
### On Button click
$SelectFileButtonPg9.Add_Click({

    $initialDirectory = [Environment]::GetFolderPath('Desktop')

    $OpenFileDialogPg9 = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialogPg9.InitialDirectory = $initialDirectory

    $OpenFileDialogPg9.Filter = 'Config file (*.txt)|*.txt'

    $OpenFileDialogPg9.Multiselect = $False
    $AcceptableFile=$False
    $response = $OpenFileDialogPg9.ShowDialog()
    ### Appropriate file type choosen
    if ($response -eq 'OK'){ 
        ###Write-Host 'You selected the file:' $OpenFileDialog.FileName ### File name
        $AcceptableFile=$True
    }
    $global:TxtFile=[String]$OpenFileDialogPg9.FileName
    
    if ($AcceptableFile){
        $SelectionLabelPg9.Text = "You have selected: " + $global:TxtFile
        $ContinueButtonPg9.Visible=$True
        $EditTXTPg9.Visible=$True
        $Global:OutputTxt=Get-Content $global:TxtFile

        $OutputBox9.lines=$Global:OutputTxt
        $OutputBox9.ReadOnly=$True
        $OutputBox9.Visible=$True
        $ReadmeBox9.Visible=$True
    }
    else{
        $SelectionLabelPg9.Text ="You have not selected a file"
        $ContinueButtonPg9.Visible=$False
        $EditTXTPg9.Visible=$False
        $OutputBox9.text=""
        $OutputBox9.Visible=$False
        $ReadmeBox9.Visible=$False
    }
})

### Select Label
$SelectionLabelPg9 = New-Object System.Windows.Forms.Label
$SelectionLabelPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$SelectionLabelPg9.Location  = New-Object System.Drawing.Point(25,650)
$SelectionLabelPg9.AutoSize = $True
$main_form.Controls.Add($SelectionLabelPg9)

### Cancel Button
$CancelEditPg9 = New-Object System.Windows.Forms.Button
$CancelEditPg9.Location = New-Object System.Drawing.Size(650,660)
$CancelEditPg9.Size = New-Object System.Drawing.Size(125,45)
$CancelEditPg9.Text = "Cancel Edit"
$CancelEditPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$CancelEditPg9.Visible=$False
$main_form.Controls.Add($CancelEditPg9)
$CancelEditPg9.Add_Click({
    $SelectFileButtonPg9.Visible=$True
    $ContinueButtonPg9.Visible=$True
    $EditTXTPg9.Visible=$True
    $SaveTXTPg9.visible=$false
    try{
        $Global:OutputTxt=Get-Content $global:TxtFile
    }
    catch{}
    $OutputBox9.lines=""
    $OutputBox9.lines+=$Global:OutputTxt
    $OutputBox9.ReadOnly=$True
    $CancelEditPg9.Visible=$False

})

### SaveButton
$SaveTXTPg9 = New-Object System.Windows.Forms.Button
$SaveTXTPg9.Location = New-Object System.Drawing.Size(825,660)
$SaveTXTPg9.Size = New-Object System.Drawing.Size(125,45)
$SaveTXTPg9.Text = "Save Edit"
$SaveTXTPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$SaveTXTPg9.Visible=$False
$main_form.Controls.Add($SaveTXTPg9)
$SaveTXTPg9.Add_Click({

    $Child_formPg9 = New-Object System.Windows.Forms.Form
    ### Title and size of window
    $Child_formPg9.Text ='Confirmation'
    $Child_formPg9.Width = 400
    $Child_formPg9.Height = 200
    $Child_formPg9.startposition = "centerscreen"
    $Child_formPg9.maximumsize = New-Object System.Drawing.Size(400,200)
    $Child_formPg9.MinimumSize  = New-Object System.Drawing.Size(400,200)
    $Child_formPg9.FormBorderStyle = 'Fixed3D'
    $Child_formPg9.MaximizeBox = $false

    ### Label
    $LabelChildPg9 = New-Object System.Windows.Forms.Label
    $LabelChildPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
    $LabelChildPg9.Location  = New-Object System.Drawing.Point(5,10)
    $LabelChildPg9.Visible=$True
    $LabelChildPg9.text="Confirm Changes?"
    $LabelChildPg9.AutoSize = $True
    $Child_formPg9.Controls.Add($LabelChildPg9)
    

    ### Cancel Button
    $CancelButtonChildPg9 = New-Object System.Windows.Forms.Button
    $CancelButtonChildPg9.Location = New-Object System.Drawing.Size(200,125) ###dif of 90
    $CancelButtonChildPg9.Size = New-Object System.Drawing.Size(85,26)
    $CancelButtonChildPg9.Text = "Cancel"
    $CancelButtonChildPg9.Visible=$True
    $Child_formPg9.Controls.Add($CancelButtonChildPg9)
    $CancelButtonChildPg9.Add_Click({
        
        $Child_formPg9.close()
        
        
    })

    ### Proceed with remediation button
    $ProceedButtonChildPg9 = New-Object System.Windows.Forms.Button
    $ProceedButtonChildPg9.Location = New-Object System.Drawing.Size(290,125)
    $ProceedButtonChildPg9.Size = New-Object System.Drawing.Size(85,26)
    $ProceedButtonChildPg9.Text = "Proceed"
    $ProceedButtonChildPg9.Visible=$True
    $Child_formPg9.Controls.Add($ProceedButtonChildPg9)
    $ProceedButtonChildPg9.Add_Click({
        ## Show Label
        $OutputBox9.lines | Set-Content -Path $global:TxtFile
        $SaveTXTPg9.visible=$false
        $CancelEditPg9.Visible=$False
        $Child_formPg9.close()

        $SelectFileButtonPg9.Visible=$True
        $ContinueButtonPg9.Visible=$True
        $EditTXTPg9.Visible=$True

        $Global:OutputTxt=Get-Content $global:TxtFile
        $OutputBox9.lines=""
        $OutputBox9.lines+=$Global:OutputTxt
        $OutputBox9.ReadOnly=$True
        $CancelEditPg9.Visible=$False
    })
    $Child_formPg9.ShowDialog()

})



### continue button
$ContinueButtonPg9 = New-Object System.Windows.Forms.Button
$ContinueButtonPg9.Location = New-Object System.Drawing.Size(990,695)
$ContinueButtonPg9.Size = New-Object System.Drawing.Size(125,45)
$ContinueButtonPg9.Text = "Continue"
$ContinueButtonPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueButtonPg9.Anchor = 'Bottom, Right'
$ContinueButtonPg9.Visible=$False
$main_form.Controls.Add($ContinueButtonPg9)
$ContinueButtonPg9.Add_Click({
    $Child_formPg9 = New-Object System.Windows.Forms.Form
    ### Title and size of window
    $Child_formPg9.Text ='Confirmation'
    $Child_formPg9.Width = 400
    $Child_formPg9.Height = 200
    $Child_formPg9.startposition = "centerscreen"
    $Child_formPg9.maximumsize = New-Object System.Drawing.Size(400,200)
    $Child_formPg9.MinimumSize  = New-Object System.Drawing.Size(400,200)
    $Child_formPg9.FormBorderStyle = 'Fixed3D'
    $Child_formPg9.MaximizeBox = $false

    ### Label
    $LabelChildPg9 = New-Object System.Windows.Forms.Label
    $LabelChildPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
    $LabelChildPg9.Location  = New-Object System.Drawing.Point(5,10)
    $LabelChildPg9.Visible=$True
    $LabelChildPg9.text="Proceed with configuration file?"
    $LabelChildPg9.AutoSize = $True
    $Child_formPg9.Controls.Add($LabelChildPg9)
    

    ### Cancel Button
    $CancelButtonChildPg9 = New-Object System.Windows.Forms.Button
    $CancelButtonChildPg9.Location = New-Object System.Drawing.Size(200,125) ###dif of 90
    $CancelButtonChildPg9.Size = New-Object System.Drawing.Size(85,26)
    $CancelButtonChildPg9.Text = "Cancel"
    $CancelButtonChildPg9.Visible=$True
    $Child_formPg9.Controls.Add($CancelButtonChildPg9)
    $CancelButtonChildPg9.Add_Click({
        
        $Child_formPg9.close()
        
        
    })

    ### Proceed with remediation button
    $ProceedButtonChildPg9 = New-Object System.Windows.Forms.Button
    $ProceedButtonChildPg9.Location = New-Object System.Drawing.Size(290,125)
    $ProceedButtonChildPg9.Size = New-Object System.Drawing.Size(85,26)
    $ProceedButtonChildPg9.Text = "Proceed"
    $ProceedButtonChildPg9.Visible=$True
    $Child_formPg9.Controls.Add($ProceedButtonChildPg9)
    $ProceedButtonChildPg9.Add_Click({
        $Back2HomeButtonPg9.Visible=$True
        $BackButtonPg9.Visible=$False
        $SelectionLabelPg9.Text = ""
        $OutputBox9.text=""
        $SelectFileButtonPg9.Visible=$False
        $EditTXTPg9.Visible=$False
        $ContinueButtonPg9.Visible=$False
        $ReadmeBox9.Visible=$False
        CheckWindows
        $Child_formPg9.close()

        # chart 1 Group before (Left side)
        $DataArrayGroup = @("Pass", "Fail")
        $DataValuesGroup=@($Global:GroupChartCountPass,$Global:GroupChartCountFail)

        $Global:Chart5.Visible
        # create chart object
        $Global:Chart5 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
        $Global:Chart5.Width = 450
        $Global:Chart5.Height = 350
        $Global:Chart5.Left = 20
        $Global:Chart5.Top = 1
        $Global:Chart5.Location = New-Object System.Drawing.Size(1000,90)
        $Global:Chart5.Visible = $True
        # $Global:Chart.Title = $global:HTMLFile2
        ### Title
        $Chart5 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $Chart5.Text = 'Configuration of Groups and Users'
        $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
        $Chart5.Font =$Font
        $Global:Chart5.Titles.Add($Chart5)
        # chart colour palette (must match data array order)
        $Global:Chart5.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
        $Global:Chart5.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red)
        # create a chartarea to draw on and add to chart
        $Global:ChartArea5 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        # $Global:ChartArea.Backgroundcolor="Orange"
        $Global:Chart5.ChartAreas.Add($Global:ChartArea5)
        # add data to chart
        [void]$Global:Chart5.Series.Add("Data")
        $Global:Chart5.Series["Data"].Points.DataBindXY($DataArrayGroup, $DataValuesGroup)
        $Global:Chart5.Series["Data"].ChartType = "Pie"
        $Global:Chart5.Series["Data"]["PieLabelStyle"] = "Outside"
        $Global:Chart5.Series["Data"]["PieDrawingStyle"] = "Concave"
        $Global:Chart5.Series["Data"]["PieLineColor"] = "Black"
        ($Global:Chart5.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
        $Global:Chart5.Series["Data"]['PieLabelStyle'] = 'Disabled'
        # Legend
        $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $Legend.IsEquallySpacedItems = $True
        $Legend.BorderColor = 'Black'
        $Global:Chart5.Legends.Add($Legend)
        $Global:Chart5.Series["Data"].LegendText = "#VALX (#PERCENT)"
        $main_form.Controls.Add($Global:Chart5)

        # chart 2 Folder before (Right side)
        $DataArrayFolder = @("Pass", "Fail")
        $DataValuesFolder=@($Global:FolderChartCountPass,$Global:FolderChartCountFail)
        # create chart object
        $Global:Chart6 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
        $Global:Chart6.Width = 450
        $Global:Chart6.Height = 350
        $Global:Chart6.Left = 20
        $Global:Chart6.Top = 1
        $Global:Chart6.Location = New-Object System.Drawing.Size(1000,470)
        $Global:Chart6.Visible = $True
        # $Global:Chart.Title = $global:HTMLFile2
        ### Title
        $Chart6 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $Chart6.Text = 'Configuration of Folders'
        $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','15', [System.Drawing.FontStyle]::Bold)
        $Chart6.Font =$Font
        $Global:Chart6.Titles.Add($Chart6)
        # chart colour palette (must match data array order)
        $Global:Chart6.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
        $Global:Chart6.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red)
        # create a chartarea to draw on and add to chart
        $Global:ChartArea6 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        # $Global:ChartArea.Backgroundcolor="Orange"
        $Global:Chart6.ChartAreas.Add($Global:ChartArea6)
        # add data to chart
        [void]$Global:Chart6.Series.Add("Data")
        $Global:Chart6.Series["Data"].Points.DataBindXY($DataArrayFolder, $DataValuesFolder)
        $Global:Chart6.Series["Data"].ChartType = "Pie"
        $Global:Chart6.Series["Data"]["PieLabelStyle"] = "Outside"
        $Global:Chart6.Series["Data"]["PieDrawingStyle"] = "Concave"
        $Global:Chart6.Series["Data"]["PieLineColor"] = "Black"
        ($Global:Chart6.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
        $Global:Chart6.Series["Data"]['PieLabelStyle'] = 'Disabled'
        # Legend
        $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $Legend.IsEquallySpacedItems = $True
        $Legend.BorderColor = 'Black'
        $Global:Chart6.Legends.Add($Legend)
        $Global:Chart6.Series["Data"].LegendText = "#VALX (#PERCENT)"
        $main_form.Controls.Add($Global:Chart6)
        
    })
    $Child_formPg9.ShowDialog()

})
### Edit text file
$EditTXTPg9 = New-Object System.Windows.Forms.Button
$EditTXTPg9.Location = New-Object System.Drawing.Size(550,650)
$EditTXTPg9.Size = New-Object System.Drawing.Size(125,45)
$EditTXTPg9.Text = "Edit"
$EditTXTPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$EditTXTPg9.Visible=$False
$main_form.Controls.Add($EditTXTPg9)
$EditTXTPg9.Add_Click({
    $SelectFileButtonPg9.Visible=$False
    $ContinueButtonPg9.Visible=$False
    $OutputBox9.ReadOnly=$False
    $EditTXTPg9.Visible=$False
    $CancelEditPg9.visible=$True
    $SaveTXTPg9.visible=$True

})

### Back button page 9 
$BackButtonPg9 = New-Object System.Windows.Forms.Button
$BackButtonPg9.Location = New-Object System.Drawing.Size(40,695)
$BackButtonPg9.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg9.Text = "Back"
$BackButtonPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg9.Visible=$False
$BackButtonPg9.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg9)
### On Button click
$BackButtonPg9.Add_Click({
    $SelectionLabelPg2.Text = ""
    $OutputBox9.text=""
    ### Goes to Page 2
    HidePage9
    ShowPage1

})

### Back button page 9
$Back2HomeButtonPg9 = New-Object System.Windows.Forms.Button
$Back2HomeButtonPg9.Location = New-Object System.Drawing.Size(40,695)
$Back2HomeButtonPg9.Size = New-Object System.Drawing.Size(125,45)
$Back2HomeButtonPg9.Text = "Back to Home Page"
$Back2HomeButtonPg9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$Back2HomeButtonPg9.Visible=$False
$Back2HomeButtonPg9.Anchor = 'Bottom'
$main_form.Controls.Add($Back2HomeButtonPg9)
### On Button click
$Back2HomeButtonPg9.Add_Click({
    $SelectionLabelPg2.Text = ""
    $OutputBox9.text=""
    ### Goes to Page 2
    HidePage9
    ShowPage1

})


    
#### Page 10
$OutputBox10 = New-Object System.Windows.Forms.TextBox
$OutputBox10.Location= New-Object System.Drawing.Size(30,90)
$OutputBox10.Size = New-Object System.Drawing.Size(650,550)
$OutputBox10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$OutputBox10.ReadOnly=$True
$OutputBox10.Multiline = $True
$OutputBox10.Visible=$False
$OutputBox10.Scrollbars = "Vertical" 
$main_form.Controls.Add($OutputBox10)

#Label
$LabelOptionPg10 = New-Object System.Windows.Forms.Label
$LabelOptionPg10.Text = "Remediate Computer Configuration by selecting a configuration file"
$LabelOptionPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 23, [System.Drawing.FontStyle]::Bold)
$LabelOptionPg10.Location  = New-Object System.Drawing.Point(5,10)
$LabelOptionPg10.AutoSize = $True
$main_form.Controls.Add($LabelOptionPg10)
$LabelOptionPg10.Visible=$False

#Description
$LabelDescPg10 = New-Object System.Windows.Forms.Label
$LabelDescPg10.Text = "Select a configuration file that is of txt file type to run."
$LabelDescPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$LabelDescPg10.Location  = New-Object System.Drawing.Point(10,50)
$LabelDescPg10.AutoSize = $True
$main_form.Controls.Add($LabelDescPg10)
$LabelDescPg10.Visible=$False

#Readme section
$ReadmeBox10 = New-Object System.Windows.Forms.TextBox
$ReadmeBox10.Text = 
"group1 represents the group name
member1 represents the members within group1
group1 cross-checks against member1 members
group2 cross-checks against member2 members 
and so on
only use a comma when adding multiple members
and no space after the commas

drive=E
choose the drive
check if folder1 and so on exists under the drive
identity1 represents the group
right1 represents the rights of identity1
folderadmin is the default admin name
do not tamper
admin1 are the rights of admins to folder1

folder1 cross-checks against
identity1, right1, admin1 and folderadmin
identity1 and right1 are cross-checked

for right1 and so on
Read, Execute -> ReadAndExecute
always include a (, Synchronize) at the end
split the rights with a comma and a space"
$ReadmeBox10.Location= New-Object System.Drawing.Size(685,90)
$ReadmeBox10.Size = New-Object System.Drawing.Size(365,550)
$ReadmeBox10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ReadmeBox10.ReadOnly=$True
$ReadmeBox10.Multiline = $True
$ReadmeBox10.Visible=$False
$ReadmeBox10.ForeColor="black"
$main_form.Controls.Add($ReadmeBox10)

### Select Button
$SelectFileButtonPg10 = New-Object System.Windows.Forms.Button
$SelectFileButtonPg10.Location = New-Object System.Drawing.Size(850,695)
$SelectFileButtonPg10.Size = New-Object System.Drawing.Size(125,45)
$SelectFileButtonPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$SelectFileButtonPg10.Text = "Select File"
$SelectFileButtonPg10.Anchor = 'Bottom, Right'
$SelectFileButtonPg10.Visible=$False
$main_form.Controls.Add($SelectFileButtonPg10)
### On Button click
$SelectFileButtonPg10.Add_Click({

    $initialDirectory = [Environment]::GetFolderPath('Desktop')

    $OpenFileDialogPg10 = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialogPg10.InitialDirectory = $initialDirectory

    $OpenFileDialogPg10.Filter = 'Config file (*.txt)|*.txt'

    $OpenFileDialogPg10.Multiselect = $False
    $AcceptableFile=$False
    $response = $OpenFileDialogPg10.ShowDialog()
    ### Appropriate file type choosen
    if ($response -eq 'OK'){ 
        #### Write-Host 'You selected the file:' $OpenFileDialogPg10.FileName ### File name
        $AcceptableFile=$True
    }
    $global:TxtFile=[String]$OpenFileDialogPg10.FileName
    
    if ($AcceptableFile){
        $SelectionLabelPg10.Text = "You have selected: " + $global:TxtFile
        $ContinueButtonPg10.Visible=$True
        $EditTXTPg10.Visible=$True
        $Global:OutputTxt=Get-Content $global:TxtFile

        $OutputBox10.lines=$Global:OutputTxt
        $OutputBox10.ReadOnly=$True
        $OutputBox10.Visible=$True
        $ReadmeBox10.Visible=$True
    }
    else{
        $SelectionLabelPg10.Text ="You have not selected a file"
        $ContinueButtonPg10.Visible=$False
        $EditTXTPg10.Visible=$False
        $OutputBox10.text=""
        $OutputBox10.Visible=$False
        $ReadmeBox10.Visible=$False
    }
})

### Select Label
$SelectionLabelPg10 = New-Object System.Windows.Forms.Label
$SelectionLabelPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 16)
$SelectionLabelPg10.Location  = New-Object System.Drawing.Point(25,650)
$SelectionLabelPg10.AutoSize = $True
$main_form.Controls.Add($SelectionLabelPg10)

### Cancel Button
$CancelEditPg10 = New-Object System.Windows.Forms.Button
$CancelEditPg10.Location = New-Object System.Drawing.Size(650,660)
$CancelEditPg10.Size = New-Object System.Drawing.Size(125,45)
$CancelEditPg10.Text = "Cancel Edit"
$CancelEditPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$CancelEditPg10.Visible=$False
$main_form.Controls.Add($CancelEditPg10)
$CancelEditPg10.Add_Click({
    $SelectFileButtonPg10.Visible=$True
    $ContinueButtonPg10.Visible=$True
    $EditTXTPg10.Visible=$True
    $SaveTXTPg10.visible=$false
    try{
        $Global:OutputTxt=Get-Content $global:TxtFile
    }
    catch{}
    $OutputBox10.lines=""
    $OutputBox10.lines+=$Global:OutputTxt
    $OutputBox10.ReadOnly=$True
    $CancelEditPg10.Visible=$False

})

### SaveButton
$SaveTXTPg10 = New-Object System.Windows.Forms.Button
$SaveTXTPg10.Location = New-Object System.Drawing.Size(825,660)
$SaveTXTPg10.Size = New-Object System.Drawing.Size(125,45)
$SaveTXTPg10.Text = "Save Edit"
$SaveTXTPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$SaveTXTPg10.Visible=$False
$main_form.Controls.Add($SaveTXTPg10)
$SaveTXTPg10.Add_Click({

    $Child_formPg10 = New-Object System.Windows.Forms.Form
    ### Title and size of window
    $Child_formPg10.Text ='Confirmation'
    $Child_formPg10.Width = 400
    $Child_formPg10.Height = 200
    $Child_formPg10.startposition = "centerscreen"
    $Child_formPg10.maximumsize = New-Object System.Drawing.Size(400,200)
    $Child_formPg10.MinimumSize  = New-Object System.Drawing.Size(400,200)
    $Child_formPg10.FormBorderStyle = 'Fixed3D'
    $Child_formPg10.MaximizeBox = $false

    ### Label
    $LabelChildPg10 = New-Object System.Windows.Forms.Label
    $LabelChildPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
    $LabelChildPg10.Location  = New-Object System.Drawing.Point(5,10)
    $LabelChildPg10.Visible=$True
    $LabelChildPg10.text="Confirm Changes?"
    $LabelChildPg10.AutoSize = $True
    $Child_formPg10.Controls.Add($LabelChildPg10)
    

    ### Cancel Button
    $CancelButtonChildPg10 = New-Object System.Windows.Forms.Button
    $CancelButtonChildPg10.Location = New-Object System.Drawing.Size(200,125) ###dif of 90
    $CancelButtonChildPg10.Size = New-Object System.Drawing.Size(85,26)
    $CancelButtonChildPg10.Text = "Cancel"
    $CancelButtonChildPg10.Visible=$True
    $Child_formPg10.Controls.Add($CancelButtonChildPg10)
    $CancelButtonChildPg10.Add_Click({
        
        $Child_formPg10.close()
        
        
    })

    ### Proceed with remediation button
    $ProceedButtonChildPg10 = New-Object System.Windows.Forms.Button
    $ProceedButtonChildPg10.Location = New-Object System.Drawing.Size(290,125)
    $ProceedButtonChildPg10.Size = New-Object System.Drawing.Size(85,26)
    $ProceedButtonChildPg10.Text = "Proceed"
    $ProceedButtonChildPg10.Visible=$True
    $Child_formPg10.Controls.Add($ProceedButtonChildPg10)
    $ProceedButtonChildPg10.Add_Click({
        ## Show Label
        $OutputBox10.lines | Set-Content -Path $global:TxtFile
        $SaveTXTPg10.visible=$false
        $CancelEditPg10.Visible=$False
        $Child_formPg10.close()

        $SelectFileButtonPg10.Visible=$True
        $ContinueButtonPg10.Visible=$True
        $EditTXTPg10.Visible=$True

        $Global:OutputTxt=Get-Content $global:TxtFile
        $OutputBox10.lines=""
        $OutputBox10.lines+=$Global:OutputTxt
        $OutputBox10.ReadOnly=$True
        $CancelEditPg10.Visible=$False
    })
    $Child_formPg10.ShowDialog()

})



### continue button
$ContinueButtonPg10 = New-Object System.Windows.Forms.Button
$ContinueButtonPg10.Location = New-Object System.Drawing.Size(990,695)
$ContinueButtonPg10.Size = New-Object System.Drawing.Size(125,45)
$ContinueButtonPg10.Text = "Continue"
$ContinueButtonPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueButtonPg10.Anchor = 'Bottom, Right'
$ContinueButtonPg10.Visible=$False
$main_form.Controls.Add($ContinueButtonPg10)
$ContinueButtonPg10.Add_Click({
    $Child_formPg10 = New-Object System.Windows.Forms.Form
    ### Title and size of window
    $Child_formPg10.Text ='Confirmation'
    $Child_formPg10.Width = 400
    $Child_formPg10.Height = 200
    $Child_formPg10.startposition = "centerscreen"
    $Child_formPg10.maximumsize = New-Object System.Drawing.Size(400,200)
    $Child_formPg10.MinimumSize  = New-Object System.Drawing.Size(400,200)
    $Child_formPg10.FormBorderStyle = 'Fixed3D'
    $Child_formPg10.MaximizeBox = $false

    ### Label
    $LabelChildPg10 = New-Object System.Windows.Forms.Label
    $LabelChildPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 17)
    $LabelChildPg10.Location  = New-Object System.Drawing.Point(5,10)
    $LabelChildPg10.Visible=$True
    $LabelChildPg10.text="Proceed with configuration file?"
    $LabelChildPg10.AutoSize = $True
    $Child_formPg10.Controls.Add($LabelChildPg10)
    

    ### Cancel Button
    $CancelButtonChildPg10 = New-Object System.Windows.Forms.Button
    $CancelButtonChildPg10.Location = New-Object System.Drawing.Size(200,125) ###dif of 90
    $CancelButtonChildPg10.Size = New-Object System.Drawing.Size(85,26)
    $CancelButtonChildPg10.Text = "Cancel"
    $CancelButtonChildPg10.Visible=$True
    $Child_formPg10.Controls.Add($CancelButtonChildPg10)
    $CancelButtonChildPg10.Add_Click({
        
        $Child_formPg10.close()
        
        
    })

    ### Proceed with remediation button
    $ProceedButtonChildPg10 = New-Object System.Windows.Forms.Button
    $ProceedButtonChildPg10.Location = New-Object System.Drawing.Size(290,125)
    $ProceedButtonChildPg10.Size = New-Object System.Drawing.Size(85,26)
    $ProceedButtonChildPg10.Text = "Proceed"
    $ProceedButtonChildPg10.Visible=$True
    $Child_formPg10.Controls.Add($ProceedButtonChildPg10)
    $ProceedButtonChildPg10.Add_Click({
        $BackButtonPg10.Visible=$False
        $Back2HomeButtonPg10.Visible=$True
        $SelectionLabelPg10.Text = ""
        $OutputBox10.text=""
        $SelectFileButtonPg10.Visible=$False
        $EditTXTPg10.Visible=$False
        $ContinueButtonPg10.Visible=$False
        $ReadmeBox10.Visible=$False
        RemediateWindows
        $Child_formPg10.close()

        # #Remediate Chart
        # # chart 1 Group before (Left side)
        # $DataArrayGroup = @("Pass", "Fail")
        # $DataValuesGroup=@($Global:RemediateGroupChartCountPass,$Global:RemediateGroupChartCountFail)
        # $Global:Chart7.Visible
        # # create chart object
        # $Global:Chart7 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
        # $Global:Chart7.Width = 450
        # $Global:Chart7.Height = 350
        # $Global:Chart7.Left = 20
        # $Global:Chart7.Top = 1
        # $Global:Chart7.Location = New-Object System.Drawing.Size(1000,90)
        # $Global:Chart7.Visible = $True
        # # $Global:Chart.Title = $global:HTMLFile2
        # # chart colour palette (must match data array order)
        # $Global:Chart7.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
        # $Global:Chart7.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red)
        # # create a chartarea to draw on and add to chart
        # $Global:ChartArea7 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        # # $Global:ChartArea.Backgroundcolor="Orange"
        # $Global:Chart7.ChartAreas.Add($Global:ChartArea7)
        # # add data to chart
        # [void]$Global:Chart7.Series.Add("Data")
        # $Global:Chart7.Series["Data"].Points.DataBindXY($DataArrayGroup, $DataValuesGroup)
        # $Global:Chart7.Series["Data"].ChartType = "Pie"
        # $Global:Chart7.Series["Data"]["PieLabelStyle"] = "Outside"
        # $Global:Chart7.Series["Data"]["PieDrawingStyle"] = "Concave"
        # $Global:Chart7.Series["Data"]["PieLineColor"] = "Black"
        # ($Global:Chart7.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
        # $Global:Chart7.Series["Data"]['PieLabelStyle'] = 'Disabled'
        # # Legend
        # $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        # $Legend.IsEquallySpacedItems = $True
        # $Legend.BorderColor = 'Black'
        # $Global:Chart7.Legends.Add($Legend)
        # $Global:Chart7.Series["Data"].LegendText = "#VALX (#PERCENT)"
        # $main_form.Controls.Add($Global:Chart7)

        # # chart 2 Folder before (Right side)
        # $DataArrayFolder = @("Pass", "Fail")
        # $DataValuesFolder=@($Global:RemediateFolderChartCountPass,$Global:RemediateFolderChartCountFail)
        # # create chart object
        # $Global:Chart8 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
        # $Global:Chart8.Width = 450
        # $Global:Chart8.Height = 350
        # $Global:Chart8.Left = 20
        # $Global:Chart8.Top = 1
        # $Global:Chart8.Location = New-Object System.Drawing.Size(1000,470)
        # $Global:Chart8.Visible = $True
        # # $Global:Chart.Title = $global:HTMLFile2
        # # chart colour palette (must match data array order)
        # $Global:Chart8.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
        # $Global:Chart8.PaletteCustomColors = @( [System.Drawing.Color]::Green,  [System.Drawing.Color]::Red)
        # # create a chartarea to draw on and add to chart
        # $Global:ChartArea8 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        # # $Global:ChartArea.Backgroundcolor="Orange"
        # $Global:Chart8.ChartAreas.Add($Global:ChartArea8)
        # # add data to chart
        # [void]$Global:Chart8.Series.Add("Data")
        # $Global:Chart8.Series["Data"].Points.DataBindXY($DataArrayFolder, $DataValuesFolder)
        # $Global:Chart8.Series["Data"].ChartType = "Pie"
        # $Global:Chart8.Series["Data"]["PieLabelStyle"] = "Outside"
        # $Global:Chart8.Series["Data"]["PieDrawingStyle"] = "Concave"
        # $Global:Chart8.Series["Data"]["PieLineColor"] = "Black"
        # ($Global:Chart8.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true
        # $Global:Chart8.Series["Data"]['PieLabelStyle'] = 'Disabled'
        # # Legend
        # $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        # $Legend.IsEquallySpacedItems = $True
        # $Legend.BorderColor = 'Black'
        # $Global:Chart8.Legends.Add($Legend)
        # $Global:Chart8.Series["Data"].LegendText = "#VALX (#PERCENT)"
        # $main_form.Controls.Add($Global:Chart8)
        
    })
    $Child_formPg10.ShowDialog()

})
### Edit text file
$EditTXTPg10 = New-Object System.Windows.Forms.Button
$EditTXTPg10.Location = New-Object System.Drawing.Size(550,650)
$EditTXTPg10.Size = New-Object System.Drawing.Size(125,45)
$EditTXTPg10.Text = "Edit"
$EditTXTPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$EditTXTPg10.Visible=$False
$main_form.Controls.Add($EditTXTPg10)
$EditTXTPg10.Add_Click({
    $SelectFileButtonPg10.Visible=$False
    $ContinueButtonPg10.Visible=$False
    $OutputBox10.ReadOnly=$False
    $EditTXTPg10.Visible=$False
    $CancelEditPg10.visible=$True
    $SaveTXTPg10.visible=$True

})

### Back button page 10
$BackButtonPg10 = New-Object System.Windows.Forms.Button
$BackButtonPg10.Location = New-Object System.Drawing.Size(40,695)
$BackButtonPg10.Size = New-Object System.Drawing.Size(125,45)
$BackButtonPg10.Text = "Back"
$BackButtonPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$BackButtonPg10.Visible=$False
$BackButtonPg10.Anchor = 'Bottom, Left'
$main_form.Controls.Add($BackButtonPg10)
### On Button click
$BackButtonPg10.Add_Click({
    $SelectionLabelPg2.Text = ""
    $OutputBox10.text=""
    ### Goes to Page 2
    HidePage10
    ShowPage1

})

$Back2HomeButtonPg10 = New-Object System.Windows.Forms.Button
$Back2HomeButtonPg10.Location = New-Object System.Drawing.Size(40,695)
$Back2HomeButtonPg10.Size = New-Object System.Drawing.Size(125,45)
$Back2HomeButtonPg10.Text = "Back to Home Page"
$Back2HomeButtonPg10.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$Back2HomeButtonPg10.Visible=$False
$Back2HomeButtonPg10.Anchor = 'Bottom'
$main_form.Controls.Add($Back2HomeButtonPg10)
### On Button click
$Back2HomeButtonPg10.Add_Click({
    $SelectionLabelPg2.Text = ""
    $OutputBox10.text=""
    ### Goes to Page 2
    HidePage10
    ShowPage1

})

$ContinueToPage9 = New-Object System.Windows.Forms.Button
$ContinueToPage9.Location = New-Object System.Drawing.Size(40,745)
$ContinueToPage9.Size = New-Object System.Drawing.Size(125,45)
$ContinueToPage9.Text = "Check Configurations"
$ContinueToPage9.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$ContinueToPage9.Visible=$False
$ContinueToPage9.Anchor = 'Bottom'
$main_form.Controls.Add($ContinueToPage9)
### On Button click
$ContinueToPage9.Add_Click({
    $SelectionLabelPg2.Text = ""
    $OutputBox10.text=""
    ### Goes to Page 9
    HidePage10
    ShowPage9

})


    
### Display the screen
$main_form.ShowDialog() ### Everything to be added before this
############ End of GUI ############ 
    
    