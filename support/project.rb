#!//usr/local/bin/ruby

project=ARGV[0]
firstuser=ARGV[1]

if project == nil or firstuser == nil
	puts "Usage: project.rb project firstuser"
	exit
end

`/usr/sbin/groupadd #{project}`
if !File.exists?("/home/#{firstuser}")
	`/usr/sbin/useradd -g #{project} -s /bin/cvssh #{firstuser}`
end
`./mkdocroot.sh #{project} #{firstuser}`
`./cvscreate.sh #{project} #{firstuser}`
`/root/gforge/update_unix_accounts.php`
`cat /etc/webalizer/csmart.conf | sed -e 's/csmart/#{project}/g' > /etc/webalizer/#{project}.conf`
