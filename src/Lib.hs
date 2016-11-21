{-# LANGUAGE OverloadedStrings #-}
module Lib
    ( startCrawler
    ) where
import qualified Data.ByteString.Lazy as B
import Data.Aeson
import Data.Set (Set, fromList, elemAt, deleteAt)
import qualified Data.Text as TE
import qualified Data.Text.IO as T
import Network.HTTP.Simple (httpSink, parseRequest)
import Text.HTML.DOM (sinkDoc)
import Text.XML.Cursor (Cursor, attribute, attributeIs, content, element, fromDocument, (&|), ($//), (&/), (&//), (&.//))
import Text.XML (Document)
import Data.Monoid ((<>))
data URL = URL {
    url:: TE.Text
  , assets:: [TE.Text]
} deriving (Eq, Show)
instance ToJSON URL where
    toJSON (URL url assets) =
        object ["url" .= url, "assets" .= assets]
startCrawler base relative = do
    let page = getPage $ base ++ relative
    links <- getLinks page
    scripts <- getScripts page
    css <- getCSS page
    img <- getImg page
    let res = URL (TE.pack $ base ++ relative) (css ++ scripts ++ img)
    crawl <- crawler (TE.pack base) (fromList $ filterNothing links) [(TE.pack relative)]
    B.putStr $ encode $ res:crawl
test = do
    result <- crawler "https://monzo.com" (fromList ["/"]) []
    B.putStrLn (encode result)
crawler:: TE.Text -> Set TE.Text -> [TE.Text] -> IO [URL]
crawler base links visited 
    | null links = return []
    | elem (elemAt 0 links) visited = crawler base (deleteAt 0 links) (visited)
    | otherwise = do
        let head = elemAt 0 links
        let page = getPage $ TE.unpack $ base <> head
        newLinks <- getLinks page 
        scripts <- getScripts page
        css <- getCSS page
        img <- getImg page
        let result = URL (base <> head) (css ++ scripts ++ img)
        next <- crawler base ( (fromList $ filterNothing newLinks)  <> (deleteAt 0 links)) (head:visited)
        return $ result:next
getLinks =  applyFilterA . getDoc 
getScripts = applyFilterScript . getDoc
getCSS = applyFilterCSS . getDoc
getImg = applyFilterImg . getDoc
getPage url = parseRequest url >>= \url -> httpSink url $ const sinkDoc
getDoc :: IO Document -> IO Cursor 
getDoc = fmap (fromDocument)
applyFilterA = fmap (\c -> c $// (element "a" &.// attribute "href") &| getRelative)
applyFilterImg = fmap (\c -> c $// element "img" &.// attribute "src")
applyFilterScript = fmap (\c -> c $// element "script" &.// attribute "src")
applyFilterCSS = fmap (\c -> c $// element "link" &.// attributeIs "rel" "stylesheet" &.// attribute "href")
getRelative x = if predicate x then Just x else Nothing
predicate "" = False
predicate x = TE.head x == '/' && if TE.length x < 2 then True else TE.head (TE.tail x) /= '/' && if TE.length x < 8 then True else TE.take 8 x /= "/cdn-cgi" 
filterNothing [] = []
filterNothing (x:xs) = case x of
    (Nothing) -> filterNothing xs
    (Just y) -> y:filterNothing xs
