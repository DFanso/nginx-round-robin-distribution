<?php
// Server information
$server_name = gethostname();
$server_ip = $_SERVER['SERVER_ADDR'];
$client_ip = $_SERVER['REMOTE_ADDR'];

// Database connection parameters
$host = 'db';
$dbname = 'testdb';
$user = 'user';
$pass = 'password';

// Connect to database
$conn = null;
$db_status = 'Not connected';
try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $user, $pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db_status = 'Connected successfully';
} catch(PDOException $e) {
    $db_status = 'Connection failed: ' . $e->getMessage();
}

// Increment visit counter in database if connected
$visit_count = 0;
if ($conn) {
    try {
        // Create table if not exists
        $conn->exec("CREATE TABLE IF NOT EXISTS visits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            hostname VARCHAR(255) NOT NULL,
            visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
        
        // Add visit record
        $stmt = $conn->prepare("INSERT INTO visits (hostname) VALUES (:hostname)");
        $stmt->bindParam(':hostname', $server_name);
        $stmt->execute();
        
        // Get visit count
        $stmt = $conn->query("SELECT COUNT(*) FROM visits");
        $visit_count = $stmt->fetchColumn();
    } catch(PDOException $e) {
        echo "Database error: " . $e->getMessage();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>BogdanLTD - Load Balancer Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0066cc;
        }
        .server-info {
            background-color: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .server-highlight {
            background-color: #e3f2fd;
            border-left: 4px solid #0066cc;
            padding: 10px 15px;
            margin-bottom: 15px;
            font-size: 18px;
            font-weight: bold;
        }
        .status {
            margin-top: 20px;
            padding: 10px;
            border-radius: 5px;
        }
        .status.success {
            background-color: #d4edda;
            color: #155724;
        }
        .status.error {
            background-color: #f8d7da;
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>BogdanLTD - Mobile Phone Store</h1>
        
        <div class="server-highlight">
            Currently Serving: <?php echo $server_name; ?> (<?php echo $server_ip; ?>)
        </div>
        
        <div class="server-info">
            <h2>Server Information</h2>
            <p><strong>Server Name:</strong> <?php echo $server_name; ?></p>
            <p><strong>Server IP:</strong> <?php echo $server_ip; ?></p>
            <p><strong>Client IP:</strong> <?php echo $client_ip; ?></p>
            <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        </div>
        
        <div class="status <?php echo ($conn ? 'success' : 'error'); ?>">
            <h2>Database Status</h2>
            <p><?php echo $db_status; ?></p>
            <?php if ($conn): ?>
                <p><strong>Total Visits:</strong> <?php echo $visit_count; ?></p>
            <?php endif; ?>
        </div>
    </div>
</body>
</html> 