-- Validate platform family mapping logic
SELECT 
    operating_system,
    platform_family
FROM {{ ref('go_device_dimension') }}
WHERE (
    (UPPER(operating_system) LIKE '%WINDOWS%' AND platform_family != 'Microsoft') OR
    (UPPER(operating_system) LIKE '%MAC%' AND platform_family != 'Apple') OR
    (UPPER(operating_system) LIKE '%IOS%' AND platform_family != 'Apple') OR
    (UPPER(operating_system) LIKE '%ANDROID%' AND platform_family != 'Google') OR
    (UPPER(operating_system) LIKE '%LINUX%' AND platform_family != 'Linux') OR
    (UPPER(operating_system) NOT LIKE '%WINDOWS%' 
     AND UPPER(operating_system) NOT LIKE '%MAC%' 
     AND UPPER(operating_system) NOT LIKE '%IOS%' 
     AND UPPER(operating_system) NOT LIKE '%ANDROID%' 
     AND UPPER(operating_system) NOT LIKE '%LINUX%' 
     AND platform_family != 'Other')
)
