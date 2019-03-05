#!/bin/bash

uninstall_mysql() {
	apt autoremove -y mysql-server
}

uninstall_mysql
