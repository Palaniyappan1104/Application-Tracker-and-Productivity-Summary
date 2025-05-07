# Define category times (in minutes)
$workTime = 0
$leisureTime = 0
$personalTime = 0
$uncategorizedTime = 0

# Tracking duration (in minutes)
$duration = 10  
$interval = 1  # Update every 1 minute
$startTime = Get-Date

# Function to categorize applications
function Categorize-Application {
    param($appName)
    if ($appName -match "Teams|Excel|PowerPoint|Word|Notepad|Code|IDE|Terminal|powershell") {
        return "Work"
    }
    elseif ($appName -match "Spotify|YouTube|Netflix|Games|Discord") {
        return "Leisure"
    }
    elseif ($appName -match "Photos|Calendar|Notes|Reminder") {
        return "Personal"
    }
    else {
        return "Uncategorized"
    }
}

# Function to get the currently active application
function Get-ActiveApplication {
    if (-not ("User32" -as [type])) {
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class User32 {
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();
            [DllImport("user32.dll")]
            public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
        }
"@
    }
    
    $hWnd = [User32]::GetForegroundWindow()
    $procId = 0
    $null = [User32]::GetWindowThreadProcessId($hWnd, [ref]$procId)
    $activeProcess = Get-Process -Id $procId -ErrorAction SilentlyContinue
    
    return $activeProcess.ProcessName
}

# Initialize tracking data
$trackingData = @()

# Main tracking loop
while ((Get-Date) -lt $startTime.AddMinutes($duration)) {
    $currentApp = Get-ActiveApplication

    if (-not $currentApp) {
        Write-Output "No active application detected."
        Start-Sleep -Seconds ($interval * 60)
        continue
    }

    $category = Categorize-Application $currentApp

    # Update time for active category
    switch ($category) {
        "Work" { $workTime += 1 }
        "Leisure" { $leisureTime += 1 }
        "Personal" { $personalTime += 1 }
        "Uncategorized" { $uncategorizedTime += 1 }
    }

    # Store data in tracking array
    $trackingData += @{
        Time = (Get-Date).ToString("HH:mm:ss")
        Application = $currentApp
        Category = $category
    }

    # Display current status
    Write-Output "`nActive Application: $currentApp"
    Write-Output "Updated Work Time: $workTime min"
    Write-Output "Updated Personal Time: $personalTime min"
    Write-Output "Updated Leisure Time: $leisureTime min"
    Write-Output "Updated Uncategorized Time: $uncategorizedTime min"

    Start-Sleep -Seconds ($interval * 60)
}

# Calculate total tracked time
$totalTime = $workTime + $leisureTime + $personalTime + $uncategorizedTime

# Calculate Productivity Score
if ($totalTime -gt 0) {
    $productivityScore = [math]::Round(($workTime / $totalTime) * 100, 2)
} else {
    $productivityScore = 0
}

# Generate the HTML report with CSS and JS fully embedded
$htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Productivity Summary</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(to bottom, #BAFF39, #FFFFFF); /* Gradient from green to white */
            text-align: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: auto;
            background: rgba(255, 255, 255, 0.8); /* Lighter background for better text visibility */
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.3);
            transition: transform 0.3s ease-in-out;
        }
        .container:hover {
            transform: scale(1.05);
        }
        h2 { 
            margin-bottom: 10px; 
            color: #FF5841; /* Vibrant orange for headings */
            font-size: 30px; 
            font-weight: bold;
        }
        .quote {
            font-size: 18px;
            font-style: italic;
            background: rgba(255, 255, 255, 0.2);
            padding: 10px;
            border-radius: 5px;
            animation: fadeIn 2s;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            background: rgba(255, 255, 255, 0.2);
        }
        th, td {
            padding: 12px;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }
        th { background: rgba(255, 255, 255, 0.3); }
        .chart-container {
            width: 90%;
            margin: 20px auto;
        }
        .pie-chart-container {
            width: 40%;
            margin: 20px auto;
        }
        .bar-chart-container {
            width: 90%;
            margin: 20px auto;
        }
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        @keyframes slideIn {
            from { transform: translateX(-100%); }
            to { transform: translateX(0); }
        }
        .slide-in {
            animation: slideIn 1s;
        }
        .bold-text {
            font-weight: bold;
            font-size: 20px;
            color: #C53678; /* Red-violet for highlighting */
        }
    </style>
</head>
<body>
    <div class='container slide-in'>
        <h2>Productivity Summary</h2>
        <p class='quote' id='quote'></p>
        <table>
            <tr><th>Category</th><th>Time Spent (min)</th></tr>
            <tr><td>Work</td><td id='workTime' class='bold-text'>$workTime</td></tr>
            <tr><td>Leisure</td><td id='leisureTime' class='bold-text'>$leisureTime</td></tr>
            <tr><td>Personal</td><td id='personalTime' class='bold-text'>$personalTime</td></tr>
            <tr><td>Uncategorized</td><td id='uncategorizedTime' class='bold-text'>$uncategorizedTime</td></tr>
        </table>
        <div class='pie-chart-container'><canvas id='pieChart'></canvas></div>
        <div class='bar-chart-container'><canvas id='barChart'></canvas></div>
    </div>

    <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
    <script>
        const quotes = [
            "Focus on being productive instead of busy.",
            "Your future is created by what you do today, not tomorrow.",
            "Small daily improvements are the key to staggering long-term results.",
            "Success is the sum of small efforts, repeated day in and day out.",
            "Don't watch the clock; do what it does. Keep going!"
        ];
        document.getElementById('quote').innerText = quotes[Math.floor(Math.random() * quotes.length)];

        const ctx1 = document.getElementById('pieChart').getContext('2d');
        new Chart(ctx1, {
            type: 'pie',
            data: {
                labels: ['Work', 'Leisure', 'Personal', 'Uncategorized'],
                datasets: [{
                    data: [$workTime, $leisureTime, $personalTime, $uncategorizedTime],
                    backgroundColor: ['#4CAF50', '#FF9800', '#2196F3', '#9E9E9E'],
                    borderColor: ['#4CAF50', '#FF9800', '#2196F3', '#9E9E9E'],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'bottom'
                    }
                }
            }
        });

        const ctx2 = document.getElementById('barChart').getContext('2d');
        new Chart(ctx2, {
            type: 'bar',
            data: {
                labels: ['Work', 'Leisure', 'Personal', 'Uncategorized'],
                datasets: [{
                    label: 'Time Spent',
                    data: [$workTime, $leisureTime, $personalTime, $uncategorizedTime],
                    backgroundColor: [
                        'rgba(76, 175, 80, 0.2)',
                        'rgba(255, 152, 0, 0.2)',
                        'rgba(33, 150, 243, 0.2)',
                        'rgba(158, 158, 158, 0.2)'
                    ],
                    borderColor: [
                        'rgba(76, 175, 80, 1)',
                        'rgba(255, 152, 0, 1)',
                        'rgba(33, 150, 243, 1)',
                        'rgba(158, 158, 158, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'bottom'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

# Define file path
$htmlFilePath = "C:\Users\Palaniyappan\Desktop\OS PROJECT\summary.html"

# Save HTML report
$htmlContent | Out-File -Encoding utf8 $htmlFilePath

# Open the generated report in the browser
Start-Process $htmlFilePath

Write-Output "`nTotal Time Tracked: $totalTime minutes"
Write-Output "Final Productivity Score: $productivityScore%"
Write-Output "Summary displayed in browser."
