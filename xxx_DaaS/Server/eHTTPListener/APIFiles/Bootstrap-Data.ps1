$configuration = @{
    ActiveDirectory = @{
        Users = @{
            User1 = @{
                Name = "TestUser0010"
                Password = "P@55w0rd"
            }
            User2 = @{
                Name = "TestUser0011"
                Password = "P@55w0rd"
            }
            User3 = @{
                Name = "TestUser0012"
                Password = "P@55w0rd"
            }
            User4 = @{
                Name = "TestUser0013"
                Password = "P@55w0rd"
            }
        }
        Groups = @{
            TaskWorkers = { "TestUser0010" }
            KnowledgeWorkers = { "TestUser0011" }
            MobileWorkers = { "TestUser0012" }
            CustomApps = { "TestUser0013" }
        }
    }
    RemoteHostsGroups = @{
        "2012Desktop" = "rdshD-*"
        "2008Desktop" = "rdshD8-*"
        "2012App" = "rdshA-*"
        "Linux" = "lnx-*"
    }
    ResourceGroups = @{
        SimpleGroup = @{
            Apps = { "Calculator", "Notepad" }
            RemoteHostGroup = "2012App"
            AdUser = "TestUser0010"
        }
        TaskWorkers = @{
            Apps = { "Calculator", "Notepad" }
            RemoteHostGroup = "2012App"
            AdGroup = "TaskWorkers"
        }
        TaskWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "TaskWorkers"
        }
        KnowledgeWorkers = @{
            Apps = { "Calculator", "Notepad", "WordPad" }
            RemoteHostGroup = "2012App"
            AdGroup = "KnowledgeWorkers"
        }
        KnowledgeWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "KnowledgeWorkers"
        }
        MobileWorkers = @{
            Apps = { "Calculator", "Notepad", "WordPad", "Paint", "Command Prompt" }
            RemoteHostGroup = "2012App"
            AdGroup = "MobileWorkers"
        }
        MobileWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "MobileWorkers"
        }
        Office = @{
            Apps = { "Calculator", "WordPad" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
        Internet = @{
            Apps = { "Notepad", "WordPad", "Internet Explorer" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
        Multimedia = @{
            Apps = { "Notepad", "WordPad", "Paint", "Command Prompt", "Internet Explorer" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
    }

}