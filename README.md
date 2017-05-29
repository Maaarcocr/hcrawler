# hcrawler
A small crawler written in Haskell

## Dependencies
In order to run this little crawler you need to install stack on your machine. You can find more about this [here](https://docs.haskellstack.org/en/stable/README/#how-to-install)

## Build and run

Build command:

    stack build

Run command: 

    stack exec crawler-exe <url-to-crawl>
    
## NB
In order to work you need to pass an url with this format: "http://domain.something".
Please do not put a "/" at the end or it will not work 


