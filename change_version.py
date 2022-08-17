import toml

doc = toml.load("pyproject.toml")
version = doc["project"]['version']

print(f'Version: {version}')
while True:
    new_version = input('New version: ')

    ans = input(f'New version: {new_version} - is it correct? [y/n] ')
    if ans == 'y':
        break

doc["project"]['version'] = new_version
file = open("pyproject.toml", "w")
toml.dump(doc, file)
file.close()

file = open('version.txt', 'w')
file.write(new_version)
file.close()