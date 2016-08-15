

#
# Ugly. 
#
function New-WordPressEnviornment()
{
    Param(
        [Parameter(Mandatory = $true)]
        [string] $Database,
        [string] $Path = "$env:USERPROFILE/Sites",
        [string] $MySqlUser = "root",
        [string] $MySqlPassword = "",
        [string] $MySqlHost = "localhost",
        [int] $SitePort = 0, 
        [string] $SiteHost = "127.0.0.1",
        [string] $DatabaseUser,
        [string] $DatabaseUserPassword,
        [string] $MySqlVersion = "current",
        [string] $PhpHost = "127.0.0.1:9000",
        [string] $Server = "nginx"
    )
    
    $appsRoot = $null;
    if($env:ChocolateyToolsLocation -ne $null) {
        $appsRoot = $env:ChocolateyToolsLocation
    } elseif ($env:ChocolateyBinRoot -ne $null) {
        $appsRoot = $env:ChocolateyBinRoot 
    }

    if($Server -ne "nginx") {
        Write-Error "Only nginx is currenly supported";
    }

    if($appsRoot -eq $null) {
        Write-Error "ChocolateyBinRoot and ChocolateyToolsLocation could not be found";
        return
    }

    if(-not (Test-Path "$appsRoot/php-fpm")) {
        Write-Error "Php-Frm is not installed.  Run `"choco install php-fpm -y`"";
        return 
    }

    if(-not (Test-Path "$appsRoot/mysql")) {
        Write-Error "Php-Frm is not installed.  Run `"choco install mysql -y`"";
        return 
    }

    if([string]::IsNullOrWhiteSpace($DatabaseUser)) {
        $DatabaseUser = "${Database}_user";
    }

    if([string]::IsNullOrWhiteSpace($DatabaseUserPassword)) {
        $DatabaseUserPassword = New-BadMishkaPassword
    }

    if($SitePort -eq 0) {
        $random = New-Object Random
        #TODO: think about higher port ranges
        $SitePort = $random.Next(2000, 7000)
    }

    if($Server -eq "nginx" -and -not (Test-Path "$appsRoot/nginx")) {
        Write-Error "nginx is not installed. Run `"choco install nginx -y`"";
    }

    if($MySqlVersion -eq "current") {
         $mysql = "$appsRoot/mysql/current/bin/mysql.exe"

         $text = & $mysql --version
         $line1 = $text; 
         $offset = $line1.IndexOf("Distrib") + 7;
         $MySqlVersion = $line1.Substring($offset, $line1.IndexOf(",") - $offset).Trim()
    }

    Write-Host $MySqlVersion
  

    if($Path -eq "$env:USERPROFILE/Sites") {
        $Path = "$Path/$Database"
    }

    if(-not (Test-Path $Path)) {
        mkdir $Path -Force
        Copy-Item "$appsRoot/wordpress/*" $Path -Recurse -Force
    }

$Path = $Path.Replace("\", "/")

$config = "
server {
        listen       $SitePort;
        server_name  $SiteHost;
        root         `"$Path`";
        index index.php index.html index.htm;
        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            try_files `$uri `$uri/ /index.php?q=`$uri&`$args;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        location ~ \.php$ {
            try_files `$uri = 404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass   $PhpHost;
            fastcgi_index  index.php;
            include        fastcgi.conf;
            include        fastcgi_params;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }
";



  
    [System.IO.File]::WriteAllText("$appsRoot/nginx/current/conf/sites-enabled/$Database.conf", $config)

   

    if(-not (Test-Path "$env:TEMP/badmishka/wordpress")) {
        mkdir "$env:TEMP/badmishka/wordpress" -Force 
    }
 

    $mysql = "$appsRoot/mysql/$MySqlVersion/bin/mysql";
    $mysqld = "$appsRoot/mysql/$MySqlVersion/bin/mysqld";

    $mysqlProcess = Get-Process mysqld -ErrorAction SilentlyContinue;
    if($mysqlProcess -eq $null) {
         $info = New-Object System.Diagnostics.ProcessStartInfo($mysqld)
         $info.WorkingDirectory = $Path 
         [System.Diagnostics.Process]::Start($info)
    }


    #TODO make atomic, consider using ADO + MySQL
    & $mysql --user=$MySqlUser --password=$MySqlPassword  --execute="CREATE DATABASE IF NOT EXISTS $Database;";
    & $mysql --user=$MySqlUser --password=$MySqlPassword  --execute="CREATE USER IF NOT EXISTS $DatabaseUser@localhost IDENTIFIED BY `'$DatabaseUserPassword`';";
    & $mysql --user=$MySqlUser --password=$MySqlPassword  --execute="GRANT ALL PRIVILEGES ON ${Database}.* TO $DatabaseUser@localhost;";
    & $mysql --user=$MySqlUser --password=$MySqlPassword  --execute="FLUSH PRIVILEGES;";


    $keysAndSalts = (New-Object System.Net.WebClient).DownloadString("https://api.wordpress.org/secret-key/1.1/salt/")

$wpConfig = "<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to `"wp-config.php`" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '$Database');

/** MySQL database username */
define('DB_USER', '$DatabaseUser');

/** MySQL database password */
define('DB_PASSWORD', '$DatabaseUserPassword');

/** MySQL hostname */
define('DB_HOST', '$MySqlHost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
$keysAndSalts

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
`$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
";
    [System.IO.File]::WriteAllText("$Path/wp-config.php", $wpConfig)


}

function Start-WordPressEnvironment()
{
    Param(
        
    )



}