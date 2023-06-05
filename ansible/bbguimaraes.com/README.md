bbguimaraes.com
===============

List existing servers:

    $ ./bbguimaraes.com.py droplets --digital-ocean-token do.txt
    248149879: bbguimaraes0

To create a new server:

    $ ./bbguimaraes.com.py \
        --verbose \
        new --digital-ocean-token do.txt bbguimaraes1
